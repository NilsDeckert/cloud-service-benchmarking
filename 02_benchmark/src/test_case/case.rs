use std::{collections::HashMap, fs::File, path::PathBuf};

use chrono::Local;
use serde::Serialize;

use crate::load_generator::{load_generator::LoadGenerator};

#[derive(Serialize)]
pub struct Timing {
    pub id: usize,
    pub duration: u128
}

pub trait Case<'a> {
    fn new(con: &'a mut redis::Connection,
        load_generator: &'a mut LoadGenerator,
        path: PathBuf) -> Self; 

    fn execute(&mut self, runs: usize);

    fn get_timings(&self) -> Vec<Timing>;
}

pub fn write_results(path: &PathBuf, timings: Vec<Timing>) {

    // Make sure we choose a unique file name
    let mut name = Local::now().format("%Y-%m-%d").to_string();
    let mut mb_f = File::create_new(path.join(format!("{name}.csv")));

    while mb_f.is_err() {
        println!("Error: {:?}", mb_f);
        name = format!("{name}_1").into();
        mb_f = File::create(&name);
    }

    println!("Saving to file {}.csv", name);

    let mut wtr = csv::Writer::from_writer(mb_f.unwrap());
    for timing in timings {
        wtr.serialize(timing).unwrap();
    }
    wtr.flush().unwrap();
}
