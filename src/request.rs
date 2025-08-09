use std::{
    collections::HashMap,
    io::{BufRead, BufReader, Read},
    net::TcpStream,
};

use serde_json::Value;

#[derive(Debug)]
pub struct Request {
    pub route: String,
    pub params: HashMap<String, String>,
    pub body: Option<Value>,
}

impl Request {
    fn new() -> Self {
        Self {
            route: String::new(),
            params: HashMap::new(),
            body: None,
        }
    }

    pub fn parse(mut reader: BufReader<&mut TcpStream>) -> Request {
        let mut request = Self::new();
        let mut headline = String::new();

        let _ = reader.read_line(&mut headline);

        let headline_parts: Vec<&str> = headline.split_whitespace().collect();
        if headline_parts.len() >= 2 {
            let method = headline_parts[0];
            let path = headline_parts[1];

            if path.contains('?') {
                let parts: Vec<&str> = path.split('?').collect();
                let base_path = parts[0];
                let query_string = parts[1];

                request.route = format!("{} {}", method, base_path);

                for param in query_string.split('&') {
                    if let Some((key, value)) = param.split_once('=') {
                        request.params.insert(key.to_string(), value.to_string());
                    }
                }
            } else {
                request.route = format!("{} {}", method, path);
            }

            let mut content_length: u64 = 0;

            for line in reader.by_ref().lines() {
                let line = line.unwrap();
                
                if line.to_lowercase().starts_with("content-length:") {
                    let parts: Vec<&str> = line.split(':').collect();
                    if parts.len() >= 2 {
                        content_length = parts[1].trim().parse::<u64>().unwrap_or(0);
                    }
                }

                if line.is_empty() {
                    break;
                }
            }

            if content_length > 0 {
                let mut body = String::new();
                let _ = reader.take(content_length).read_to_string(&mut body);

                if let Ok(parsed) = serde_json::from_str(&body) {
                    request.body = Some(parsed);
                }
            }
        }

        request
    }
}