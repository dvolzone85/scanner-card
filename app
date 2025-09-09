// Config demo
const CONFIG = {
  USE_GOOGLE_VISION: false,
  GOOGLE_API_KEY: "", // se vuoi usare Vision, metti la tua API key e imposta USE_GOOGLE_VISION = true
};

class GoogleVisionOCR {
  constructor(apiKey){
    this.apiKey = apiKey;
    this.apiUrl = "https://vision.googleapis.com/v1/images:annotate";
  }
  async extractTextFromImage(base64){
    const content = base64.replace(/^data:image\/(png|jpg|jpeg);base64,/, "");
    const body = {
      requests: [{
        image: { content },
        features: [{ type: "DOCUMENT_TEXT_DETECTION", maxResults: 1 }]
      }]
    };
    const r = await fetch(`${this.apiUrl}?key=${this.apiKey}`, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify(body)
    });
    const data = await r.json();
    return data.responses?.[0]?.fullTextAnnotation?.text || "";
  }
}

// Utility
const toBase64 = file => new Promise((res, rej) => {
  const reader = new FileReader();
  reader.onload = () => res(reader.result);
  reader.onerror = rej;
  reader.readAsDataURL(file);
});

function parseContact(text){
  const lines = text.split(/\r?\n/).map(s => s.trim()).filter(Boolean);
  const email = (text.match(/[\w.+-]+@[\w-]+\.[\w.-]+/i) || [])[0] || "";
  const tel = (text.match(/(?:\+?\d{1,3}[\s.]*)?(?:\(?\d{2,4}\)?[\s.]*)?\d{3}[\s.]?\d{3,4}[\s.]?\d{0,4}/) || [])[0] || "";
  return { nome: lines[0]||"", azienda: lines[1]||"", email, tel, raw: text };
}

function renderContacts(list){
  const ul = document.getElementById("contactsList");
  ul.innerHTML = "";
  list.forEach(c => {
    const li = document.createElement("li");
    li.textContent = `${c.nome||"—"} · ${c.azienda||"—"} · ${c.email||"—"} · ${c.tel||"—"}`;
    ul.appendChild(li);
  });
}

(async function init(){
  const stored = JSON.parse(localStorage.getItem("businessCards") || "[]");
  renderContacts(stored);

  const fileInput = document.getElementById("fileInput");
  const scanBtn = document.getElementById("scanBtn");
  const clearBtn = document.getElementById("clearBtn");
  const out = document.getElementById("output");

  const ocr = CONFIG.USE_GOOGLE_VISION && CONFIG.GOOGLE_API_KEY
    ? new GoogleVisionOCR(CONFIG.GOOGLE_API_KEY)
    : null;

  scanBtn.addEventListener("click", async () => {
    if (!fileInput.files.length){ out.textContent = "Seleziona un'immagine."; return; }
    out.textContent = "Elaborazione…";
    try {
      const b64 = await toBase64(fileInput.files[0]);
      let text;
      if (ocr){
        text = await ocr.extractTextFromImage(b64);
      } else {
        // DEMO fittizia
        text = "Mario Rossi\nACME srl\nm.rossi@example.com\n+39 333 1234567";
      }
      out.textContent = text;
      const contact = parseContact(text);
      const list = JSON.parse(localStorage.getItem("businessCards") || "[]");
      list.push(contact);
      localStorage.setItem("businessCards", JSON.stringify(list));
      renderContacts(list);
    } catch(e){
      console.error(e);
      out.textContent = "Errore durante la scansione.";
    }
  });

  clearBtn.addEventListener("click", () => {
    localStorage.removeItem("businessCards");
    renderContacts([]);
  });
})();
