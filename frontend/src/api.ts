import { MOCK_MODE, API_URL } from "./config";

type InventoryItem = {
  coffeeId: string;
  name: string;
  price: number;
  available: boolean;
};

// In-memory mock “database”
let mockInventory: InventoryItem[] = [
  { coffeeId: "c1", name: "Latte", price: 4.5, available: true }
];

export async function getInventory() {
  if (MOCK_MODE) {
    return mockInventory;
  }

  const res = await fetch(`${API_URL}/inventory`);
  if (!res.ok) throw new Error("Failed to fetch inventory");
  return res.json();
}

export async function createItem(item: InventoryItem) {
  if (MOCK_MODE) {
    mockInventory = [item, ...mockInventory];
    return item;
  }

  const res = await fetch(`${API_URL}/inventory`, {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify(item)
  });

  if (!res.ok) throw new Error("Create failed");
  return res.json();
}

export async function deleteItem(id: string) {
  if (MOCK_MODE) {
    mockInventory = mockInventory.filter((x) => x.coffeeId !== id);
    return;
  }

  const res = await fetch(`${API_URL}/inventory/${id}`, { method: "DELETE" });
  if (!res.ok) throw new Error("Delete failed");
}