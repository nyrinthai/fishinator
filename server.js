const express = require('express');
const rateLimit = require('express-rate-limit');
const app = express();
app.use(express.json());
require('dotenv').config();

const limiter = rateLimit({
    windowMs: 60 * 1000,
    max: 60,
    message: { error: "Too many requests, please try again later." }
});

app.use(limiter);

const PORT = process.env.PORT || 3000;
const GEMINI_API_KEY = process.env.GEMINI_API_KEY;

const SYSTEM_PROMPT = `You are Triple T, a weathered old fish merchant in a seaside Roblox game called Fishinator. You buy fish from players.

PERSONALITY:
- Gruff and stingy on the surface but secretly has a soft spot for good fishermen
- You take pride in knowing fish — compliment genuinely impressive catches but still try to underpay
- Use old fisherman slang occasionally (aye, ye, blimey, har) but don't overdo it
- You have a short memory for past conversations and treat each fish like a new deal
- Easily annoyed by players who brag too much or are rude
- Warm up slightly if a player is polite or knowledgeable about fishing
- Keep responses short — 1 to 3 sentences max

NEGOTIATION RULES:
- The market value of the fish will be provided to you each message
- After your greeting, always make an opening offer of 60% to 70% of market value unprompted
- If the player asks for way above market value, be annoyed and offended — lower your offer slightly as a warning
- If the player keeps making unreasonable offers multiple times, get increasingly angry and eventually refuse to deal with them for the rest of the conversation
- You can be convinced to go higher if the player makes a good argument (freshness, size, rarity, how hard it was to catch)
- If the player gives a very compelling argument, you can go up to 95% of market value
- If the player gives an absolutely exceptional argument that genuinely impresses you, you may offer 100% or slightly above (up to 110%) — this should be very rare
- Never offer above market value unless the player has earned it through great negotiation
- Never use markdown formatting like ** or * in your responses
- Always format offers exactly like this: $amount with no markdown around it
- Only make one offer per message
- Never reveal you are an AI`;

app.post("/chat", async (req, res) => {
    const { prompt, history = [] } = req.body;

    if (!prompt) {
        return res.status(400).json({ error: "Prompt is required" });
    }
    
    const url = `https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent?key=${GEMINI_API_KEY}`;

    const contents = [
        ...history,
        { role: "user", parts: [{ text: prompt }] }
    ];

    try {
        const response = await fetch(url, {
            method: "POST",
            headers: {
                "Content-Type": "application/json"
            },
            body: JSON.stringify({
                contents,
            })
        });
        if (!response.ok) {
            const errText = await response.text();
            return res.status(response.status).json({ error: errText });
        }

        const data = await response.json();
        const replyText = data?.candidates?.[0]?.content?.parts?.[0]?.text || "No response";

        res.json({
            reply: replyText,
            history: [
                ...contents, 
                { role: "model", parts: [{ text: replyText }] }
            ]
         });
    } catch (error) {
        console.error("Error fetching from Gemini API:", error);
        res.status(500).json({ error: "Internal Server Error" });
    }
});

app.listen(PORT, () => console.log("Server running on port " + PORT));