import { getQuery, postQuery } from "@/app/api/user/graphql";

export async function GET() {
  try {
    const apiToken = process.env.API_TOKEN;

    if (!apiToken) {
      return new Response(JSON.stringify({ error: "API Token is missing" }), {
        status: 400,
        headers: { "Content-Type": "application/json" },
      });
    }

    const response = await fetch("https://api.monday.com/v2", {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        Authorization: apiToken,
      },
      body: JSON.stringify({
        query: getQuery,
      }),
    });

    if (!response.ok) {
      return new Response(
        JSON.stringify({ error: "Failed to fetch data from the API" }),
        {
          status: response.status,
          headers: { "Content-Type": "application/json" },
        }
      );
    }

    const data = await response.json();

    return new Response(JSON.stringify(data), {
      status: 200,
      headers: { "Content-Type": "application/json" },
    });
  } catch (error) {
    console.error("Unexpected error:", error);
    return new Response(JSON.stringify({ error: "Internal Server Error" }), {
      status: 500,
      headers: { "Content-Type": "application/json" },
    });
  }
}

export async function POST(req: Request) {
  try {
    const apiToken = process.env.API_TOKEN;
    if (!apiToken) {
      return new Response(JSON.stringify({ error: "API Token is missing" }), {
        status: 400,
        headers: { "Content-Type": "application/json" },
      });
    }

    const { id } = await req.json();
    const dynamicQuery = postQuery(id);

    const response = await fetch("https://api.monday.com/v2", {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        Authorization: apiToken,
      },
      body: JSON.stringify({
        query: dynamicQuery,
      }),
    });

    if (!response.ok) {
      return new Response(
        JSON.stringify({ error: "Failed to send data to the API" }),
        {
          status: response.status,
          headers: { "Content-Type": "application/json" },
        }
      );
    }

    const data = await response.json();
    return new Response(JSON.stringify(data), {
      status: 200,
      headers: { "Content-Type": "application/json" },
    });
  } catch (error) {
    console.error("Unexpected error:", error);
    return new Response(JSON.stringify({ error: "Internal Server Error" }), {
      status: 500,
      headers: { "Content-Type": "application/json" },
    });
  }
}
