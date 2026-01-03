/// This test case adapts the statistical modeling for key-value stores proposed in
/// Berk Atikoglu, Yuehai Xu, Eitan Frachtenberg, Song Jiang, and Mike Paleczny. 2012.
/// Workload analysis of a large-scale key-value store.
/// SIGMETRICS Perform. Eval. Rev. 40, 1 (June 2012), 53–64.
/// https://doi.org/10.1145/2318857.2254766
use std::{path::PathBuf, time::{Duration, Instant}};
use crate::{load_generator::load_generator::LoadGenerator, test_case::case::{Case, Timing}};

pub struct ETC<'a> {
    con: &'a mut redis::Connection,
    load_generator: &'a mut LoadGenerator,
    path: PathBuf,
    duration: Vec<Duration>
}

impl<'a> Case<'a> for ETC<'a> {

    fn new(con: &'a mut redis::Connection,
        load_generator: &'a mut LoadGenerator,
        path: PathBuf) -> Self {

        assert!(path.is_file() == false);

        Self {
            con,
            load_generator,
            path,
            duration: vec!()
        }
    }

    fn execute(&mut self, runs: usize) {
        let lg = &mut self.load_generator;
        let mut start = std::time::Instant::now();
        for i in 0..runs {
            // Time batches of 10
            if i % 10 == 0 && i != 0 {
                self.duration.push(start.elapsed());
                start = Instant::now();
            }
            let res = lg.cmd_get().query::<redis::Value>(self.con);
            if let Err(e) = res {
                println!("Error: {}", e.category());
            }
        }
    }

    fn get_timings(&self) -> Vec<Timing> {
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
