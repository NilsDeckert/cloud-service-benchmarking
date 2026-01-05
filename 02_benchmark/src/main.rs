use std::path::PathBuf;
use std::thread;
use std::time::Duration;

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
use crate::test_case::case::write_results;
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
const KEY_LEN_MAX: u32 = 1000;
const VAL_LEN_MAX: u32 = 1000;

// --------------------------------- \\

#[derive(Parser, Debug)]
#[command(version, about, long_about = None)]
struct Args {
    /// Instance address to connect to
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
    skip_logs: bool
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

#[allow(unused)]
fn main() {
    let args = Args::parse();

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
        let mut addr = vec![];
        for s in &args.address {
            addr.push(format!("redis://{}:{}", s, args.port));
        }

        let handle = thread::spawn(move || {

            // Somehow need to save both types Connection and ClusterConnection in same variable
            let mut con: Box<dyn redis::ConnectionLike>;
            if args.cluster {
                println!("Running in cluster mode!");
                let client = redis::cluster::ClusterClient::new(addr).unwrap();
                let mut c = client.get_connection().unwrap();
                c.check_connection();
                con = Box::new(c);
            } else {
                let client = redis::Client::open(addr[0].clone()).expect("Failed to create client");
                con = Box::new(test_connection(&client, "client").expect("Connection failed"));
            }

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
                let _ = etc.get_timings();
            }

        });
        handles.push(handle);
    }

    let mut timings = vec![];
    for handle in handles {
        &mut handle.join().unwrap();
        // timings.append(&mut handle.join().unwrap());
    }

    let total = pretty_duration(&start.elapsed(), None);

    println!("Done! Took {total}");

    if !args.skip_logs {
        write_results(&PathBuf::from("./target/"), timings);
    }
}
