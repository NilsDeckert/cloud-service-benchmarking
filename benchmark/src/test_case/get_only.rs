use std::{path::PathBuf, time::{Duration, Instant}};

use crate::{load_generator::{load_generator::LoadGenerator}, test_case::case::Case};


pub struct GetOnly<'a> {
    con: &'a mut redis::Connection,
    load_generator: &'a mut LoadGenerator,
    path: PathBuf,
    duration: Duration
}

impl<'a> Case<'a> for GetOnly<'a> {

    fn new(con: &'a mut redis::Connection,
        load_generator: &'a mut LoadGenerator,
        path: PathBuf) -> Self {
        Self {
            con,
            load_generator,
            path,
            duration: Duration::new(0, 0)
        }
    }

    fn execute(&mut self, runs: usize) {
        let lg = &mut self.load_generator;
        let start = Instant::now();
        for _ in 0..runs {
            let _ = lg.cmd_get().query::<redis::Value>(self.con);
        }
        self.duration = start.elapsed();
    }
}
