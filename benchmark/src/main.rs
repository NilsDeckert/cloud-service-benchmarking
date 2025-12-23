use std::path::PathBuf;
use std::thread;
use std::time::Duration;

// Send commands to redis
use redis::{RedisResult, Value};

// CLI argument parsing
use clap::{Parser};

// Create benchmark data
mod load_generator;
use crate::load_generator::load_generator::LoadGenerator;
use crate::test_case::case::write_results;
use crate::test_case::get_only::GetOnly;

// Get test cases
mod test_case;
use test_case::case::Case;

// ---------------------------- \\

const NUM_REQ: usize = 10_000;
const ADDR: &str = "localhost";

// ---------------------------- \\


#[derive(Parser, Debug)]
#[command(version, about, long_about = None)]
struct Args {
    /// Instance address to connect to
    #[arg(short, long, default_value_t=String::from(ADDR))]
    address: String,

    /// Number of threads to send commands from
    #[arg(short, long, default_value_t=thread::available_parallelism().unwrap().get())]
    threads: usize,

    /// Number of requests to send per client
    #[arg(short, long, default_value_t=NUM_REQ)]
    requests: usize
}

/// Open connection, send ping command. Return connection
fn test_connection(client: &redis::Client, name: &str) -> RedisResult<redis::Connection>{
    let mut con = client.get_connection_with_timeout(Duration::new(3,0))?;
    let mut cmd = redis::Cmd::new();

    let ping = cmd.arg("PING").query::<redis::Value>(&mut con);
    if let Ok(Value::SimpleString(s)) = ping {
        println!("{name}: {s}");
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

    let x = args.threads;
    let mut handles = vec![];

    for i in 0..x {
        let addr = format!("redis://{}/", args.address);
        let handle = thread::spawn(move || {
            let acdis_client  = redis::Client::open(addr.clone()).expect("Failed to create acdis client");
            let mut acdis_con = test_connection(&acdis_client,  "acdis").expect("Connection failed");
            let mut lg = LoadGenerator::new(0, 100, 0, 100).expect("Error creating load generator");

            let mut get_only = GetOnly::new(
                &mut acdis_con,
                &mut lg,
                "./hallo".into()
            );

            get_only.execute(args.requests);
            get_only.get_timings()
        });
        handles.push(handle);
    }

    let mut timings = vec!();
    for handle in handles {
        timings.append(&mut handle.join().unwrap());
    }

    write_results(&PathBuf::from("./target/"), timings);
}
