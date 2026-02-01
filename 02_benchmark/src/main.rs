use std::path::PathBuf;
use std::thread;
use std::time::Duration;

use std::collections::HashMap;

// Pretty print timings
use pretty_duration::pretty_duration;

// Send commands to redis
use redis::{ConnectionLike, RedisResult, Value};

// CLI argument parsing
use clap::Parser;

// Create benchmark data
mod load_generator;
use crate::load_generator::etc_load::EtcLoadGenerator;
use crate::load_generator::load_generator::LoadGenerator;
use crate::test_case::case::{ResultHistogram, create_csv, write_histograms, write_results};
use crate::test_case::get_only::GetOnly;
use crate::test_case::set_only::SetOnly;
use crate::test_case::etc::ETC;

// Get test cases
mod test_case;
use test_case::case::Case;

// -------- Default Values --------- \\

const NUM_REQ: usize = 10_000;
const ADDR: &str = "localhost";
const KEY_LEN_MIN: u32 = 0;
const VAL_LEN_MIN: u32 = 0;
const KEY_LEN_MAX: u32 = 100;
const VAL_LEN_MAX: u32 = 1000;

// --------------------------------- \\

#[derive(Parser, Debug)]
#[command(version, about, long_about = None)]
struct Args {
    /// Instance address(es) to connect to
    #[arg(short, long, value_delimiter = ',', default_values_t=vec![String::from(ADDR)])]
    address: Vec<String>,

    /// Instance port to connect to
    #[arg(short, long, default_value_t=6379)]
    port: usize,

    /// Number of threads to send commands from
    #[arg(short, long, default_value_t=thread::available_parallelism().unwrap().get())]
    threads: usize,

    /// Number of requests to send per client
    #[arg(short, long, default_value_t=NUM_REQ)]
    requests: usize,

    /// Type of requests to send
    #[arg(short, long, value_delimiter = ',', default_values_t=vec![String::from("etc")])]
    cmd: Vec<String>,

    /// Flag to enable or disable writing result csv
    #[arg(long)]
    cluster: bool,

    /// Flag to disable writing result csv
    #[arg(long)]
    skip_logs: bool,

    /// Name of the output file
    #[arg(short, long, default_value_t=String::from("histogram"))]
    output: String,
}

/// Open connection, send ping command. Return connection
fn test_connection(client: &redis::Client, name: &str) -> RedisResult<redis::Connection> {
    let mut con = client.get_connection_with_timeout(Duration::new(3, 0))?;
    let mut cmd = redis::Cmd::new();

    let ping = cmd.arg("PING").query::<redis::Value>(&mut con);
    if let Ok(Value::SimpleString(s)) = ping {
        assert!(s == "PONG");
    } else {
        println!("{name}: Ping failed");
        if let Err(e) = ping {
            println!("{e}");
            return Err(e);
        }
    }

    Ok(con)
}

/// Given an address, initiate a connection for either single-node or cluster setups
fn init_connection(addr: &Vec<String>, cluster: bool) -> Box<dyn redis::ConnectionLike> {
    let con: Box<dyn redis::ConnectionLike>;

    if cluster {
        println!("Running in cluster mode!");
        let client = redis::cluster::ClusterClient::new(addr.clone()).unwrap();
        let mut c = client.get_connection().unwrap();
        c.check_connection();
        con = Box::new(c);
    } else {
        let client = redis::Client::open(addr[0].clone()).expect("Failed to create client");
        con = Box::new(test_connection(&client, "client").expect("Connection failed"));
    }

    con
}

/// Run some SET commands to warmup the instance
fn run_warmup(addr: &Vec<String>, requests: usize, cluster: bool) {

    println!("Running warm up...");
    let mut con = init_connection(&addr, cluster);

    let mut lg = LoadGenerator::new(
        KEY_LEN_MIN,
        KEY_LEN_MAX,
        VAL_LEN_MIN,
        VAL_LEN_MAX).expect("Error creating load generator");

    println!("SET");
    let mut set_only = SetOnly::new(&mut *con, &mut lg, "./hallo".into());
    set_only.execute(requests);
}

#[allow(unused)]
fn main() {
    let args = Args::parse();

    let mut addr = vec![];
    for s in &args.address {
        addr.push(format!("redis://{}:{}", s, args.port));
    }

    run_warmup(&addr, args.requests / 10, args.cluster);

    println!(
        "Sending {} * {} requests to {:?}...",
        args.threads, args.requests, args.address
    );

    let mut handles = vec![];

    let start = std::time::Instant::now();
    println!("{:?}", args.cmd);
    let get = args.cmd.contains(&String::from("get"));
    let set = args.cmd.contains(&String::from("set"));
    let etc = args.cmd.contains(&String::from("etc"));

    for i in 0..args.threads {
        let addr_clone = addr.clone();
        let handle = thread::spawn(move || {

            // Collect measurements
            let mut histograms = HashMap::<String, hdrhistogram::Histogram<u64>>::new();

            let mut con: Box<dyn redis::ConnectionLike> = init_connection(&addr_clone, args.cluster);

            let mut lg = LoadGenerator::new(
                KEY_LEN_MIN,
                KEY_LEN_MAX,
                VAL_LEN_MIN,
                VAL_LEN_MAX).expect("Error creating load generator");

            if set {
                println!("SET");
                let mut set_only = SetOnly::new(&mut *con, &mut lg, "./hallo".into());
                set_only.execute((args.requests / args.threads));
            }

            if get {
                println!("GET");
                let mut get_only = GetOnly::new(&mut *con, &mut lg, "./hallo".into());
                get_only.execute((args.requests / args.threads));
                // get_only.get_timings();
            }

            if etc {
                println!("ETC");
                let mut etc_lg = EtcLoadGenerator::new();
                let mut etc = ETC::new(&mut *con, &mut etc_lg, "./hallo".into());
                etc.execute((args.requests / args.threads));
                // let _ = etc.get_timings();
                histograms.extend(etc.get_histograms());
            }

            return histograms;

        });
        handles.push(handle);
    }

    let total = pretty_duration(&start.elapsed(), None);
    println!("Done! Took {total}");

    let mut file = create_csv(&args.output, &PathBuf::from("./target/")).unwrap();
    let mut sum = 0;
    let mut written = 0;
    println!("Total handles: {}", handles.len());
    for (id, handle) in handles.into_iter().enumerate() {
        let histograms = handle.join().unwrap();
        for v in histograms.values() {
            sum += v.len();
        }
        written += write_histograms(&mut file, histograms.clone(), id);
    }
    println!("Entries: {sum}");
    println!("Actually written: {written}");

    // let mut timings = vec![];
    // if !args.skip_logs {
    //     write_results(&PathBuf::from("./target/"), timings);
    // }
}
