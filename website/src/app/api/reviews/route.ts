import { NextResponse } from "next/server";
import { submitReview } from "@/lib/data";

export async function POST(request: Request) {
  try {
    const body = await request.json();
    const reviewerName = String(body.reviewerName ?? "").trim();
    const reviewBody = String(body.body ?? "").trim();
    const rating = Number(body.rating);
    const reviewerRole = body.reviewerRole
      ? String(body.reviewerRole).trim()
      : undefined;

    if (!reviewerName || !reviewBody || rating < 1 || rating > 5) {
      return NextResponse.json({ error: "Invalid input" }, { status: 400 });
    }

    await submitReview({
      reviewerName,
      reviewerRole,
      rating,
      body: reviewBody,
    });

    return NextResponse.json({ ok: true });
  } catch (error) {
    const message = error instanceof Error ? error.message : "Server error";
    return NextResponse.json({ error: message }, { status: 500 });
  }
}
