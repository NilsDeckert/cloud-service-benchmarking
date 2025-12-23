use std::path::PathBuf;

use crate::load_generator::{load_generator::LoadGenerator};

pub trait Case<'a> {
    fn new(con: &'a mut redis::Connection,
        load_generator: &'a mut LoadGenerator,
        path: PathBuf) -> Self; 

    fn execute(&mut self, runs: usize);
}
