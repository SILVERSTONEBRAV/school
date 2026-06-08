"use client";

import { useState } from "react";
export function ReviewForm() {
  const [name, setName] = useState("");
  const [role, setRole] = useState("");
  const [rating, setRating] = useState(5);
  const [body, setBody] = useState("");
  const [status, setStatus] = useState<"idle" | "loading" | "done" | "error">(
    "idle",
  );
  const [message, setMessage] = useState("");

  async function onSubmit(e: React.FormEvent) {
    e.preventDefault();
    setStatus("loading");
    try {
      const res = await fetch("/api/reviews", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({
          reviewerName: name,
          reviewerRole: role || undefined,
          rating,
          body,
        }),
      });
      if (!res.ok) {
        const data = await res.json();
        throw new Error(data.error ?? "Failed to submit");
      }
      setStatus("done");
      setMessage("Thank you! Your review will appear after admin approval.");
      setName("");
      setRole("");
      setRating(5);
      setBody("");
    } catch (err) {
      setStatus("error");
      setMessage(err instanceof Error ? err.message : "Failed to submit review");
    }
  }

  return (
    <form onSubmit={onSubmit} className="card space-y-4">
      <h3 className="text-lg font-semibold text-slate-900">Share your experience</h3>
      <div className="grid gap-4 sm:grid-cols-2">
        <label className="block text-sm">
          <span className="text-slate-700">Your name</span>
          <input
            required
            value={name}
            onChange={(e) => setName(e.target.value)}
            className="mt-1 w-full rounded-lg border border-slate-300 px-3 py-2"
          />
        </label>
        <label className="block text-sm">
          <span className="text-slate-700">Role (optional)</span>
          <input
            value={role}
            onChange={(e) => setRole(e.target.value)}
            placeholder="Parent, Alumni..."
            className="mt-1 w-full rounded-lg border border-slate-300 px-3 py-2"
          />
        </label>
      </div>
      <label className="block text-sm">
        <span className="text-slate-700">Rating</span>
        <select
          value={rating}
          onChange={(e) => setRating(Number(e.target.value))}
          className="mt-1 w-full rounded-lg border border-slate-300 px-3 py-2"
        >
          {[5, 4, 3, 2, 1].map((n) => (
            <option key={n} value={n}>
              {n} stars
            </option>
          ))}
        </select>
      </label>
      <label className="block text-sm">
        <span className="text-slate-700">Review</span>
        <textarea
          required
          rows={4}
          value={body}
          onChange={(e) => setBody(e.target.value)}
          className="mt-1 w-full rounded-lg border border-slate-300 px-3 py-2"
        />
      </label>
      <button
        type="submit"
        disabled={status === "loading"}
        className="btn-primary disabled:opacity-60"
      >
        {status === "loading" ? "Submitting..." : "Submit review"}
      </button>
      {message ? (
        <p
          className={`text-sm ${status === "error" ? "text-red-600" : "text-green-700"}`}
        >
          {message}
        </p>
      ) : null}
    </form>
  );
}
