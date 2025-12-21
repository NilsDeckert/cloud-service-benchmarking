use std::time::Duration;

use redis::{RedisResult, Value};

extern crate redis;

fn test_connection(client: &redis::Client, name: &str) -> RedisResult<()>{
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

    Ok(())
}

fn main() {
    let redis_client  = redis::Client::open("redis://34.163.77.237/").expect("Failed to create redis client");
    let valkey_client = redis::Client::open("redis://34.155.91.70/").expect("Failed to create valkey client");
    let acdis_client  = redis::Client::open("redis://localhost/").expect("Failed to create acdis client");
    let keydb_client  = redis::Client::open("redis://34.163.49.76/").expect("Failed to create keydb client");

    println!("Testing connections...");
    let _ = test_connection(&redis_client,  "redis");
    let _ = test_connection(&valkey_client, "valkey");
    let _ = test_connection(&acdis_client,  "acdis");
    let _ = test_connection(&keydb_client,  "keydb");
}
