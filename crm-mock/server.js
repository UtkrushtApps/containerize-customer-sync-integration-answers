"use strict";

const express = require("express");
const morgan = require("morgan");
const { randomUUID } = require("crypto");

const app = express();

// Configuration via environment variables with sensible defaults
const port = parseInt(process.env.PORT || "8080", 10);
const failureRate = (() => {
  const raw = process.env.FAILURE_RATE || "0.3";
  const parsed = Number.parseFloat(raw);
  if (Number.isNaN(parsed) || parsed < 0 || parsed > 1) {
    console.warn(
      `[CRM] Invalid FAILURE_RATE='${raw}' provided, falling back to 0.3`
    );
    return 0.3;
  }
  return parsed;
})();

// Middlewares
app.use(express.json({ limit: "1mb" }));
app.use(morgan("combined"));

// Simple liveness / readiness endpoint for Docker healthcheck
app.get("/health", (req, res) => {
  res.json({ status: "UP" });
});

// Simulated CRM endpoint for creating/upserting customers
app.post("/crm/customers", (req, res) => {
  const requestId = req.headers["x-request-id"] || randomUUID();
  const customer = req.body;

  if (!customer || typeof customer !== "object") {
    console.error(
      `[CRM] requestId=${requestId} - Invalid payload: body is missing or not JSON`
    );
    return res.status(400).json({
      message: "Invalid customer payload: request body must be JSON",
      requestId,
    });
  }

  if (!customer.id || !customer.email) {
    console.error(
      `[CRM] requestId=${requestId} - Invalid payload: missing required fields (id, email)`
    );
    return res.status(400).json({
      message: "Invalid customer payload: 'id' and 'email' are required",
      requestId,
    });
  }

  const roll = Math.random();
  const shouldFail = roll < failureRate;

  if (shouldFail) {
    // Simulate transient server-side error
    console.error(
      `[CRM] requestId=${requestId} - Simulated transient failure for customerId=${customer.id}, roll=${roll.toFixed(
        3
      )}`
    );

    return res.status(503).json({
      message: "Simulated transient CRM failure. Please retry.",
      requestId,
    });
  }

  console.info(
    `[CRM] requestId=${requestId} - Successfully received customerId=${customer.id}, email=${customer.email}`
  );

  // Typical REST response for creation would be 201 Created
  return res.status(201).json({
    message: "Customer accepted by mock CRM",
    requestId,
  });
});

// Basic 404 handler so unexpected routes are explicit
app.use((req, res) => {
  console.warn(`[CRM] 404 - Path not found: ${req.method} ${req.originalUrl}`);
  res.status(404).json({ message: "Not Found" });
});

// Global error handler to avoid leaking stack traces in responses
app.use((err, req, res, next) => {
  const requestId = req.headers["x-request-id"] || randomUUID();

  console.error(
    `[CRM] requestId=${requestId} - Unhandled error:`,
    err && err.stack ? err.stack : err
  );

  res.status(500).json({
    message: "Internal server error in mock CRM",
    requestId,
  });
});

app.listen(port, () => {
  console.log(
    `[CRM] Mock CRM service listening on port ${port}, failureRate=${failureRate}`
  );
});
