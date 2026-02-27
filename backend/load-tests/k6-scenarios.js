import http from 'k6/http';
import { check, sleep } from 'k6';
import { Trend, Rate } from 'k6/metrics';

const BASE_URL = __ENV.BASE_URL || 'http://localhost:8080';

export const authLatency = new Trend('auth_latency_ms');
export const businessLatency = new Trend('business_latency_ms');
export const notificationLatency = new Trend('notification_latency_ms');
export const degradedResponses = new Rate('degraded_responses_rate');

export const options = {
  scenarios: {
    massive_auth: {
      executor: 'ramping-vus',
      startVUs: 10,
      stages: [
        { duration: '1m', target: 100 },
        { duration: '2m', target: 300 },
        { duration: '1m', target: 0 },
      ],
      exec: 'massiveAuth',
    },
    business_api_burst: {
      executor: 'constant-arrival-rate',
      rate: 200,
      timeUnit: '1s',
      duration: '3m',
      preAllocatedVUs: 100,
      maxVUs: 400,
      exec: 'businessApiRequests',
      startTime: '30s',
    },
    notifications_storm: {
      executor: 'constant-vus',
      vus: 80,
      duration: '2m',
      exec: 'notificationsLoad',
      startTime: '1m',
    },
  },
  thresholds: {
    http_req_failed: ['rate<0.05'],
    http_req_duration: ['p(95)<1200'],
    auth_latency_ms: ['p(95)<900'],
    business_latency_ms: ['p(95)<1100'],
    notification_latency_ms: ['p(95)<1000'],
    degraded_responses_rate: ['rate<0.10'],
  },
};

function markDegraded(res) {
  degradedResponses.add(res.status >= 500 || res.timings.duration > 1500);
}

export function massiveAuth() {
  const payload = JSON.stringify({
    phone: '+79990000000',
    password: 'password',
  });

  const res = http.post(`${BASE_URL}/api/auth/login`, payload, {
    headers: { 'Content-Type': 'application/json' },
  });

  authLatency.add(res.timings.duration);
  markDegraded(res);

  check(res, {
    'auth status is 200/401': (r) => r.status === 200 || r.status === 401,
  });

  sleep(0.2);
}

export function businessApiRequests() {
  const res = http.get(`${BASE_URL}/api/parts/all`);
  businessLatency.add(res.timings.duration);
  markDegraded(res);

  check(res, {
    'business API responded': (r) => [200, 401, 403].includes(r.status),
  });
}

export function notificationsLoad() {
  const body = JSON.stringify({ message: 'k6 ping' });
  const res = http.post(`${BASE_URL}/api/public/ws/notifications/broadcast`, body, {
    headers: { 'Content-Type': 'application/json' },
  });

  notificationLatency.add(res.timings.duration);
  markDegraded(res);

  check(res, {
    'notification endpoint accepted': (r) => r.status === 200,
  });

  sleep(0.1);
}
