use std::{thread, time::Instant};
use std::time::Duration;
use redis::{RedisResult, Value};

use crate::load_generator::load_generator::LoadGenerator;

mod load_generator;

const NUM_REQ: u32 = 100000;

extern crate redis;

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
    // let redis_client  = redis::Client::open("redis://34.163.77.237/").expect("Failed to create redis client");
    // let valkey_client = redis::Client::open("redis://34.155.91.70/").expect("Failed to create valkey client");
    // let keydb_client  = redis::Client::open("redis://34.163.49.76/").expect("Failed to create keydb client");

    println!("Testing connections...");
    // let mut redis_con = test_connection(&redis_client,  "redis").expect("Connection failed");
    // let mut valkey_con = test_connection(&valkey_client, "valkey").expect("Connection failed");
    // let mut keydb_con = test_connection(&keydb_client,  "keydb").expect("Connection failed");
    
    let x = 10;
    let mut handles = vec![];

    for i in 0..x {
        let handle = thread::spawn(move || {
            let acdis_client  = redis::Client::open("redis://localhost/").expect("Failed to create acdis client");
            let mut acdis_con = test_connection(&acdis_client,  "acdis").expect("Connection failed");
            let mut lg = LoadGenerator::new(0, 100, 0, 100).expect("Error creating load generator");

            let start = Instant::now();
            for _ in 0..NUM_REQ {
                lg.cmd_set().query::<redis::Value>(&mut acdis_con);
                lg.cmd_get().query::<redis::Value>(&mut acdis_con);
            }
            let duration = start.elapsed();

            duration
        });
00
        handles.push(handle);
    }

    for handle in handles {
        let duration = handle.join().unwrap();
        println!("Took {:?} ({:?} per request)", duration, duration/NUM_REQ);
    }
}
