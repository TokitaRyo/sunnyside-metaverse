import fs from "node:fs";
import path from "node:path";
import { fileURLToPath } from "node:url";
import { defineConfig, type Plugin } from "vite";

/**
 * マップエディタの「保存」を受ける開発専用のAPI（POST /__editor/save）。
 * client/src/config/map.json を書き換える。上書き前のファイルは reference/map-backups/ に退避する。
 * dev サーバーは LAN にも公開されるので、書き込みはこのPC自身(localhost)からのリクエストに限る。
 */
function mapSaver(): Plugin {
  return {
    name: "map-saver",
    apply: "serve",
    configureServer(server) {
      server.middlewares.use("/__editor/save", (req, res) => {
        const remote = req.socket.remoteAddress ?? "";
        const local = remote === "127.0.0.1" || remote === "::1" || remote === "::ffff:127.0.0.1";
        if (!local) {
          res.statusCode = 403;
          return void res.end("localhost からのみ保存できます");
        }
        if (req.method !== "POST") {
          res.statusCode = 405;
          return void res.end("POST only");
        }
        const chunks: Buffer[] = [];
        req.on("data", (c: Buffer) => chunks.push(c));
        req.on("end", () => {
          try {
            const json = JSON.parse(Buffer.concat(chunks).toString("utf8"));
            if (!json?.layers?.collision || !json.width || !json.height) throw new Error("map.json の形式ではありません");
            const file = path.resolve(server.config.root, "src/config/map.json");
            const backupDir = path.resolve(server.config.root, "../reference/map-backups");
            fs.mkdirSync(backupDir, { recursive: true });
            const stamp = new Date().toISOString().replace(/[:.]/g, "-").slice(0, 19);
            const backup = path.join(backupDir, `map-${stamp}.json`);
            if (fs.existsSync(file)) fs.copyFileSync(file, backup);
            fs.writeFileSync(file, JSON.stringify(json));
            res.end(`元のファイルは ${path.relative(path.resolve(server.config.root, ".."), backup).replace(/\\/g, "/")} に退避しました。`);
          } catch (e) {
            res.statusCode = 400;
            res.end(e instanceof Error ? e.message : String(e));
          }
        });
      });
    },
  };
}

export default defineConfig({
  plugins: [mapSaver()],
  server: {
    host: true, // 同一LANのスマホからも開けるように
    port: 5173,
    // 開発中も、ショー画面（show.html）が管理用 API（/admin/api/...）を同じ場所から呼べるように、サーバー(2567)へ渡す
    proxy: { "/admin": "http://localhost:2567" },
  },
  build: {
    // 入口は2つ: ゲーム本体(index.html)と、管理者用のショー画面(show.html。/admin/show からだけ配る)
    rollupOptions: {
      input: {
        main: path.resolve(path.dirname(fileURLToPath(import.meta.url)), "index.html"),
        show: path.resolve(path.dirname(fileURLToPath(import.meta.url)), "show.html"),
      },
    },
    chunkSizeWarningLimit: 2000, // Phaser 単体で ~1.2MB
  },
});
