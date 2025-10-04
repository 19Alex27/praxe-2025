import http from "k6/http";
import { check, sleep } from "k6";

// 10 виртуальных пользователей, 15 секунд
export const options = { vus: 10, duration: "15s" };

// Приложение доступно с хоста на 8080; из контейнера k6 используем host.docker.internal
const BASE = "http://host.docker.internal:8080";

export default function () {
  const res = http.get(`${BASE}/api/hello`);
  check(res, { "status is 200": (r) => r.status === 200 });
  sleep(1);
}
