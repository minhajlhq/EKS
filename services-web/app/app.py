from flask import Flask, jsonify
import os

app = Flask(__name__)

# Optional Redis support (used when REDIS_URL is provided)
r = None
redis_url = os.getenv("REDIS_URL")
if redis_url:
    import redis
    r = redis.from_url(redis_url)

@app.route("/healthz")
def healthz():
    return jsonify(status="ok"), 200

@app.route("/")
def root():
    return "hello world", 200

@app.route("/counter")
def counter():
    if not r:
        return jsonify(error="redis not configured"), 200
    val = r.incr("hits")
    return jsonify(hits=val), 200

if __name__ == "__main__":
    # Dev only; production will use Gunicorn
    app.run(host="0.0.0.0", port=8080)

    #
