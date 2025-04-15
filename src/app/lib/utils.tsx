import { MemberObj } from "@/app/lib/interface";

export const getMemberObjByName = (
  name: string,
  members: MemberObj[]
): MemberObj | undefined => {
  return members.find((m) => m.name === name);
};

// Helper functions (encode and decode as before)
export const encodeBase64 = (data: any) => {
  const jsonString = JSON.stringify(data);
  const utf8Array = new TextEncoder().encode(jsonString);
  let binary = "";
  utf8Array.forEach((byte) => {
    binary += String.fromCharCode(byte);
  });
  return btoa(binary);
};

export const decodeBase64 = (data: string) => {
  try {
    const decodedString = atob(data);
    const utf8Array = Array.from(decodedString).map((char) =>
      char.charCodeAt(0)
    );
    const jsonString = new TextDecoder().decode(new Uint8Array(utf8Array));
    return JSON.parse(jsonString);
  } catch (e) {
    return [];
  }
};

// Function to get URL parameters (Base64 encoded)
export const getURLParams = () => {
  const params = new URLSearchParams(window.location.search);
  const membersParam = params.get("members");
  const itemArrParam = params.get("itemArr");

  return {
    members: membersParam ? decodeBase64(membersParam) : [],
    itemArr: itemArrParam ? decodeBase64(itemArrParam) : [],
  };
};

export const getShortUrl = async (longUrl: string): Promise<string> => {
  const apiToken = process.env.TINY_TOKEN;

  try {
    const response = await fetch(`https://api.tinyurl.com/create`, {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        Authorization: `Bearer ${apiToken}`,
      },
      body: JSON.stringify({
        url: longUrl,
        domain: "tinyurl.com",
      }),
    });

    if (!response.ok) {
      throw new Error(`TinyURL error: ${response.statusText}`);
    }

    const result = await response.json();
    return result.data.tiny_url;
  } catch (error) {
    console.warn("Failed to shorten URL, using original:", error);
    return longUrl;
  }
};
