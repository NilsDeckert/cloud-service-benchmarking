use core::panic;
use std::{collections::HashMap, fs::File, io::Write, path::PathBuf};

use chrono::Local;
use serde::Serialize;

use crate::load_generator::{load_generator::LoadGenerator};

#[derive(Serialize)]
pub struct Timing {
    pub id: usize,
    pub duration: u128
}

pub trait ResultHistogram {
    /// Return a map CMD -> Latencies
    fn get_histograms(&self) -> HashMap<String, hdrhistogram::Histogram<u64>>;
}

pub trait Case<'a> {
    fn new(con: &'a mut dyn redis::ConnectionLike,
        load_generator: &'a mut LoadGenerator,
        path: PathBuf) -> Self; 

    fn execute(&mut self, runs: usize);

    fn get_timings(&self) -> Vec<Timing>;
}

pub fn create_csv(base: &str, dir: &PathBuf) -> Result<File, std::io::Error> {
    // Make sure we choose a unique file name
    let mut name = Local::now().format("%Y-%m-%d").to_string() + "_" + &base;
    let mut mb_f = File::create_new(dir.join(format!("{name}.csv")));

    while mb_f.is_err() {
        name = format!("{name}_1").into();
        mb_f = File::create_new(format!("{name}.csv"));
    }

    mb_f
}

pub fn write_results(path: &PathBuf, timings: Vec<Timing>) {

    // Make sure we choose a unique file name
    let mb_f = create_csv("res", path);

    let mut wtr = csv::Writer::from_writer(mb_f.unwrap());
    for timing in timings {
        wtr.serialize(timing).unwrap();
    }
    wtr.flush().unwrap();
}

/// Write to csv
/// thread, cmd, latency, count
/// 0, GET, 42, 5
pub fn write_histograms(file: &mut File, histograms: HashMap<String, hdrhistogram::Histogram<u64>>, id: usize) -> u64 {
    if file.metadata().unwrap().len() == 0 {
        writeln!(file, "# Args: {:?}", std::env::args().collect::<Vec<_>>()).unwrap();
        let _ = csv::Writer::from_writer(&mut *file).write_record(&["thread", "cmd", "latency", "count"]);
    }

    let mut wtr = csv::Writer::from_writer(file);

    let mut sum = 0;
    for (cmd, histogram) in histograms.iter() {
        for record in histogram.iter_recorded() {
            let latency = record.value_iterated_to();
            let count = record.count_at_value();
            wtr.write_record(&[
                id.to_string(),
                cmd.to_string(),
                latency.to_string(),
                count.to_string()
            ]).unwrap();
            sum += count;
        }
    }

    return sum;
}
