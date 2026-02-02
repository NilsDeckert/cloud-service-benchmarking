/// This test case adapts the statistical modeling for key-value stores proposed in
/// Berk Atikoglu, Yuehai Xu, Eitan Frachtenberg, Song Jiang, and Mike Paleczny. 2012.
/// Workload analysis of a large-scale key-value store.
/// SIGMETRICS Perform. Eval. Rev. 40, 1 (June 2012), 53–64.
/// https://doi.org/10.1145/2318857.2254766
use std::{path::PathBuf, time::{Duration, Instant}};
use rand::Rng;
use redis::RedisResult;
use std::collections::HashMap;
use hdrhistogram::Histogram;

use crate::{load_generator::etc_load::EtcLoadGenerator, test_case::case::{Case, ResultHistogram, Timing}};

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
    dur_get: Histogram::<u64>,
    dur_set: Histogram::<u64>,
    dur_del: Histogram::<u64>,
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
            ratio: HashMap::new(),
            dur_get: Histogram::<u64>::new_with_bounds(1, 60 * 60 * 1000, 2).unwrap(),
            dur_set: Histogram::<u64>::new_with_bounds(1, 60 * 60 * 1000, 2).unwrap(),
            dur_del: Histogram::<u64>::new_with_bounds(1, 60 * 60 * 1000, 2).unwrap(),
        }
    }

    pub fn execute(&mut self, runs: usize) {

        for _i in 0..runs {

            let u: f32 = rand::rng().random();
            let res = match u {
                0.0..ETC_PERC_GET => self.query_and_log(SupportedCMDs::GET),
                ETC_PERC_GET..ETC_PERC_CUM_SET => self.query_and_log(SupportedCMDs::SET),
                ETC_PERC_CUM_SET..1.0 => self.query_and_log(SupportedCMDs::DEL),
                _ => panic!("This shouldn't happen")
            };

            if let Err(e) = res {
                println!("[ETC] Error: {}", e.category());
                if let Some(detail) = e.detail() {
                    println!("Details: {detail}");
                }
                if let Some(code) = e.code() {
                    println!("Code: {code}");
                }
            }
        }
    }

    /// Execute a redis CMD and add +1 to the respective counter
    fn query_and_log(&mut self, cmd: SupportedCMDs) -> RedisResult<redis::Value> {
        let lg = &mut self.load_generator;

        // Increase or insert count
        if let Some(cnt) = self.ratio.get_mut(&cmd) {
            *cnt += 1;
        } else {
            self.ratio.insert(cmd.clone(), 1);
        }

        let start = std::time::Instant::now();
        match cmd {
            SupportedCMDs::GET => {
                let ret = lg.cmd_get().query::<redis::Value>(self.con);
                let _ = self.dur_get.record(start.elapsed().as_micros() as u64);
                ret
            },
            SupportedCMDs::SET => {
                let ret = lg.cmd_set().query::<redis::Value>(self.con);

                let _ = self.dur_set.record(start.elapsed().as_micros() as u64);
                ret
            }
            SupportedCMDs::DEL => {
                let ret = lg.cmd_del().query::<redis::Value>(self.con);

                let _ = self.dur_del.record(start.elapsed().as_micros() as u64);
                ret
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

impl ResultHistogram for ETC<'_> {
    fn get_histograms(&self) -> HashMap<String, hdrhistogram::Histogram<u64>> {
        let mut ret = HashMap::<String, hdrhistogram::Histogram<u64>>::new();
        ret.insert(String::from("GET"), self.dur_get.clone());
        ret.insert(String::from("SET"), self.dur_set.clone());
        ret.insert(String::from("DEL"), self.dur_del.clone());
        
        ret
    }
}
