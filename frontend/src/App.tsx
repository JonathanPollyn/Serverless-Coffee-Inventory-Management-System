import { useEffect, useMemo, useState } from "react";
import { getInventory, createItem, deleteItem } from "./api.ts";
import "./style.css";

export default function App() {
  const [items, setItems] = useState<any[]>([]);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string>("");

  const [isOpen, setIsOpen] = useState(false);

  const [name, setName] = useState("");
  const [price, setPrice] = useState<string>("");
  const [available, setAvailable] = useState(true);

  async function load() {
    setError("");
    setLoading(true);
    try {
      const data = await getInventory();
      setItems(Array.isArray(data) ? data : []);
    } catch (e: any) {
      console.error("GET inventory failed:", e);
      setError(e?.message || String(e));
    } finally {
      setLoading(false);
    }
  }

  useEffect(() => {
    load();
  }, []);

  useEffect(() => {
    function onKeyDown(e: KeyboardEvent) {
      if (e.key === "Escape") setIsOpen(false);
    }
    if (isOpen) window.addEventListener("keydown", onKeyDown);
    return () => window.removeEventListener("keydown", onKeyDown);
  }, [isOpen]);

  function openModal() {
    setError("");
    setName("");
    setPrice("");
    setAvailable(true);
    setIsOpen(true);
  }

  const canSave = useMemo(() => {
    const p = Number(price);
    return name.trim().length > 0 && Number.isFinite(p) && p > 0 && !loading;
  }, [name, price, loading]);

  async function saveCoffee() {
    setError("");

    const parsedPrice = Number(price);
    if (!name.trim()) {
      setError("Name is required.");
      return;
    }
    if (!Number.isFinite(parsedPrice) || parsedPrice <= 0) {
      setError("Price must be a positive number.");
      return;
    }

    setLoading(true);
    try {
      const item = {
        coffeeId: "c" + Date.now(),
        name: name.trim(),
        price: parsedPrice,
        available
      };

      await createItem(item);
      await load();
      setIsOpen(false);
    } catch (e: any) {
      console.error("POST failed:", e);
      setError(e?.message || String(e));
    } finally {
      setLoading(false);
    }
  }

  async function remove(id: string) {
    setError("");
    setLoading(true);
    try {
      await deleteItem(id);
      await load();
    } catch (e: any) {
      console.error("DELETE failed:", e);
      setError(e?.message || String(e));
    } finally {
      setLoading(false);
    }
  }

  return (
    <div className="app">
      <h2 className="title">Coffee Inventory</h2>

      <button className="btn" onClick={openModal} disabled={loading}>
        Add Coffee
      </button>

      {error ? (
        <div className="error">
          <strong>Error:</strong> {error}
        </div>
      ) : null}

      <ul className="list">
        {items.map((i: any) => (
          <li key={i.coffeeId} className="listItem">
            <span>
              {i.name} <span className="muted">(${i.price})</span>{" "}
              {!i.available ? <span className="badge">unavailable</span> : null}
            </span>

            <button className="btn btnDanger" onClick={() => remove(i.coffeeId)} disabled={loading}>
              Delete
            </button>
          </li>
        ))}
      </ul>

      {isOpen ? (
        <div className="modalOverlay" onClick={() => setIsOpen(false)}>
          <div className="modal" onClick={(e) => e.stopPropagation()}>
            <div className="modalHeader">
              <h3 className="modalTitle">Add Coffee</h3>
              <button className="iconBtn" onClick={() => setIsOpen(false)} disabled={loading}>
                ×
              </button>
            </div>

            <div className="modalBody">
              <label className="field">
                <span className="label">Name</span>
                <input
                  className="input"
                  value={name}
                  onChange={(e) => setName(e.target.value)}
                  placeholder="e.g., Mocha"
                  disabled={loading}
                />
              </label>

              <label className="field">
                <span className="label">Price</span>
                <input
                  className="input"
                  value={price}
                  onChange={(e) => setPrice(e.target.value)}
                  placeholder="e.g., 4.75"
                  inputMode="decimal"
                  disabled={loading}
                />
              </label>

              <label className="checkRow">
                <input
                  type="checkbox"
                  checked={available}
                  onChange={(e) => setAvailable(e.target.checked)}
                  disabled={loading}
                />
                <span>Available</span>
              </label>
            </div>

            <div className="modalFooter">
              <button className="btn btnGhost" onClick={() => setIsOpen(false)} disabled={loading}>
                Cancel
              </button>
              <button className="btn" onClick={saveCoffee} disabled={!canSave}>
                {loading ? "Saving..." : "Save"}
              </button>
            </div>

            <div className="hint">Tip: press Esc to close.</div>
          </div>
        </div>
      ) : null}
    </div>
  );
}