use std::{path::PathBuf, time::{Duration, Instant}};

use crate::{load_generator::load_generator::LoadGenerator, test_case::case::{Case, Timing}};


pub struct SetOnly<'a> {
    con: &'a mut dyn redis::ConnectionLike,
    load_generator: &'a mut LoadGenerator,
    path: PathBuf,
    duration: Vec<Duration>
}

impl<'a> Case<'a> for SetOnly<'a> {

    fn new(con: &'a mut dyn redis::ConnectionLike,
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
            let res = lg.cmd_set().query::<redis::Value>(self.con);
            if let Err(e) = res {
                println!("Error: {}", e.category());
                if let Some(detail) = e.detail() {
                    println!("Details: {detail}");
                }
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
