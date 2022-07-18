const cluster = require("cluster");
const http = require("http");
const process = require("process");
const numCPUs = require("os").cpus().length;

console.log(`numCPUs: ${numCPUs}`);

// 親プロセスの処理
if (cluster.isPrimary) {
  // コア数分の子プロセスを起動
  for (let i = 0; i < numCPUs; i++) {
    cluster.fork();
  }

  // 親プロセスが死んだときに子プロセスも死ぬ
  cluster.on("exit", (worker, code, signal) => {
    console.log(`worker ${worker.process.pid} died`);
  });

  // 子プロセスの処理
} else {
  http
    .createServer((req, res) => {
      res.writeHead(200);
      res.end("Hello World");
    })
    .listen(8000);

  console.log(`Worker ${process.pid} started`);
}
