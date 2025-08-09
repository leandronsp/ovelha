use std::{
    io::{BufReader, Write},
    net::{TcpListener, TcpStream},
};
use std::{sync::Arc, thread};

use queue::Queue;
use redis_pool::ConnectionPool;
use request::Request;

mod queue;
mod redis_pool;
mod request;
mod router;
mod store;

fn main() {
    let listener: TcpListener = TcpListener::bind("0.0.0.0:3000").unwrap();
    println!("🐑 Ovelha server starting on port 3000...");

    // Configuration from environment variables
    let redis_pool_size: usize = std::env::var("API_REDIS_POOL_SIZE")
        .unwrap_or_else(|_| "10".to_string())
        .parse()
        .expect("Invalid API_REDIS_POOL_SIZE");
    
    let thread_pool_size: usize = std::env::var("API_THREAD_POOL_SIZE")
        .unwrap_or_else(|_| "10".to_string())
        .parse()
        .expect("Invalid API_THREAD_POOL_SIZE");

    println!("🐑 API Redis pool size: {}, Thread pool size: {}", redis_pool_size, thread_pool_size);

    // Initialize Redis connection pool
    let redis_pool = Arc::new(
        ConnectionPool::new("redis://redis:6379/0", redis_pool_size)
            .expect("Failed to create Redis connection pool"),
    );

    let queue: Arc<Queue<TcpStream>> = Arc::new(Queue::new());

    (0..thread_pool_size).for_each(|_| {
        let queue = Arc::clone(&queue);
        let pool = Arc::clone(&redis_pool);

        thread::spawn(move || loop {
            let client = queue.pop();
            handle(client, pool.clone());
        });
    });

    for client in listener.incoming() {
        let client = client.unwrap();
        queue.push(client);
    }
}

fn handle(mut client: TcpStream, pool: Arc<ConnectionPool>) {
    let reader = BufReader::new(&mut client);
    let request = Request::parse(reader);

    let (status, body) = route(request, pool);

    let status_text = match status {
        200 => "OK",
        404 => "Not Found",
        500 => "Internal Server Error",
        _ => "Unknown",
    };

    let response = format!(
        "HTTP/1.1 {} {}\r\nContent-Type: application/json\r\nContent-Length: {}\r\n\r\n{}",
        status,
        status_text,
        body.len(),
        body
    );

    let _ = client.write_all(response.as_bytes());
}

fn route(request: Request, pool: Arc<ConnectionPool>) -> (u16, String) {
    match request.route.as_str() {
        "POST /payments" => router::post::payments(request, pool),
        "GET /payments-summary" => router::get::payments_summary(request, pool),
        "POST /purge-payments" => router::post::purge_payments(request, pool),
        _ => router::get::not_found(),
    }
}
