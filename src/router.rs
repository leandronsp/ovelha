pub mod get {
    use crate::request::Request;
    use crate::store::Store;
    use crate::redis_pool::ConnectionPool;
    use serde_json::json;
    use std::sync::Arc;

    pub fn payments_summary(request: Request, pool: Arc<ConnectionPool>) -> (u16, String) {
        let store = Store::new(pool);

        let from = request.params.get("from").map(|s| s.as_str());
        let to = request.params.get("to").map(|s| s.as_str());

        println!("🐑 Received query params: from={:?}, to={:?}", from, to);

        match store.summary(from, to) {
            Ok(summary) => (200, summary.to_string()),
            Err(_) => (500, json!({"error": "Internal Server Error"}).to_string()),
        }
    }

    pub fn not_found() -> (u16, String) {
        (404, json!({"error": "Not Found"}).to_string())
    }
}

pub mod post {
    use crate::request::Request;
    use crate::store::Store;
    use crate::redis_pool::ConnectionPool;
    use serde_json::json;
    use std::sync::Arc;

    pub fn payments(request: Request, pool: Arc<ConnectionPool>) -> (u16, String) {
        if let Some(body) = request.body {
            let correlation_id = body["correlationId"].as_str().unwrap_or("");
            let amount = body["amount"].as_f64().unwrap_or(0.0);

            let payload = json!({
                "correlationId": correlation_id,
                "amount": amount,
                "requestedAt": chrono::Utc::now().to_rfc3339_opts(chrono::SecondsFormat::Millis, true)
            });

            match pool.get() {
                Ok(mut conn) => {
                    match redis::cmd("PUBLISH")
                        .arg("payments")
                        .arg(payload.to_string())
                        .query::<i32>(&mut *conn)
                    {
                        Ok(_) => (200, json!({"message": "enqueued"}).to_string()),
                        Err(_) => (500, json!({"error": "Redis publish failed"}).to_string()),
                    }
                },
                Err(_) => (500, json!({"error": "Redis connection failed"}).to_string()),
            }
        } else {
            (400, json!({"error": "Invalid request"}).to_string())
        }
    }

    pub fn purge_payments(_request: Request, pool: Arc<ConnectionPool>) -> (u16, String) {
        let store = Store::new(pool);

        match store.purge_all() {
            Ok(_) => (200, json!({"message": "purged"}).to_string()),
            Err(_) => (500, json!({"error": "Internal Server Error"}).to_string()),
        }
    }
}

