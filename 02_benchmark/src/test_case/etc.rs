/// This test case adapts the statistical modeling for key-value stores proposed in
/// Berk Atikoglu, Yuehai Xu, Eitan Frachtenberg, Song Jiang, and Mike Paleczny. 2012.
/// Workload analysis of a large-scale key-value store.
/// SIGMETRICS Perform. Eval. Rev. 40, 1 (June 2012), 53–64.
/// https://doi.org/10.1145/2318857.2254766
use std::{path::PathBuf, time::{Duration, Instant}};
use rand::Rng;
use redis::RedisResult;
use std::collections::HashMap;

use crate::{load_generator::etc_load::EtcLoadGenerator, test_case::case::{Case, Timing}};

/// Percentage of GET requests
const ETC_PERC_GET: f32 = 21_000 as f32 / 30_000 as f32;
/// Percentage of SET requests
const ETC_PERC_SET: f32 = 1_500 as f32 / 30_000 as f32;
/// Percentage of DEL requests
const ETC_PERC_DEL: f32 = 7_500 as f32 / 30_000 as f32;

/// Cumulative percentage of SET and GET requests
const ETC_PERC_CUM_SET: f32 = ETC_PERC_GET + ETC_PERC_SET;

// Make sure our probabilities actualy add up to 1.0
const _: () = assert!(ETC_PERC_GET + ETC_PERC_SET + ETC_PERC_DEL == 1 as f32);

pub struct ETC<'a> {
    con: &'a mut dyn redis::ConnectionLike,
    load_generator: &'a mut EtcLoadGenerator,
    _path: PathBuf,
    duration: Vec<Duration>,
    ratio: HashMap<SupportedCMDs, u32>
}

#[derive(Hash, Eq, PartialEq, Clone)]
enum SupportedCMDs {
    SET,
    GET,
    DEL
}

// impl<'a> Case<'a> for ETC<'a> {
impl<'a> ETC<'a> {

    pub fn new(con: &'a mut dyn redis::ConnectionLike,
        load_generator: &'a mut EtcLoadGenerator,
        path: PathBuf) -> Self {

        assert!(path.is_file() == false);

        Self {
            con,
            load_generator,
            _path: path,
            duration: vec!(),
            ratio: HashMap::new()
        }
    }

    pub fn execute(&mut self, runs: usize) {
        let mut start = std::time::Instant::now();

        for i in 0..runs {
            // Time batches of 10
            if i % 10 == 0 && i != 0 {
                self.duration.push(start.elapsed());
                start = Instant::now();
            }

            let u: f32 = rand::rng().random();
            let res = match u {
                0.0..ETC_PERC_GET => self.query_and_log(SupportedCMDs::GET),
                ETC_PERC_GET..ETC_PERC_CUM_SET => self.query_and_log(SupportedCMDs::SET),
                ETC_PERC_CUM_SET..1.0 => self.query_and_log(SupportedCMDs::DEL),
                _ => panic!("This shouldn't happen")
            };

            if let Err(e) = res {
                println!("Error: {}", e.category());
                if let Some(detail) = e.detail() {
                    println!("Details: {detail}");
                }
                if let Some(code) = e.code() {
                    println!("Code: {code}");
                }
            }
        }
    }

    fn query_and_log(&mut self, cmd: SupportedCMDs) -> RedisResult<redis::Value> {
        let lg = &mut self.load_generator;

        // Increase or insert count
        if let Some(cnt) = self.ratio.get_mut(&cmd) {
            *cnt += 1;
        } else {
            self.ratio.insert(cmd.clone(), 1);
        }

        match cmd {
            SupportedCMDs::GET => {
                lg.cmd_get().query::<redis::Value>(self.con)
            },
            SupportedCMDs::SET => {
                lg.cmd_set().query::<redis::Value>(self.con)
            }
            SupportedCMDs::DEL => {
                lg.cmd_del().query::<redis::Value>(self.con)
            }
        }
    }

    pub fn get_timings(&self) -> Vec<Timing> {
        let total: u32 = self.ratio.values().sum();
        println!("Total requests: {total} ({:.3}% GET, {:.3}% SET, {:.3}% DEL)",
            (self.ratio[&SupportedCMDs::GET] as f32 / total as f32) * 100.0,
            (self.ratio[&SupportedCMDs::SET] as f32 / total as f32) * 100.0,
            (self.ratio[&SupportedCMDs::DEL] as f32 / total as f32) * 100.0,
        );

        let mut timings: Vec<Timing> = vec!();

        for i in 0..self.duration.len() {
            let t = Timing{
                id: i,
                duration: self.duration[i].as_micros()
            };

            timings.push(t);
        }
        timings
    }
}
