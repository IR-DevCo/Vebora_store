import axios from "axios";

const API_BASE = process.env.NEXT_PUBLIC_API_BASE || "http://127.0.0.1:8000";

// ===============================
// Plan APIs
// ===============================
export const fetchPlans = async () => {
  try {
    const response = await axios.get(`${API_BASE}/users/plans`);
    return response.data; // array of plans
  } catch (error: any) {
    console.error("Failed to fetch plans:", error);
    return [];
  }
};

// ===============================
// Subscribe User
// ===============================
export const subscribeUser = async (user_id: number, plan_id: number) => {
  try {
    const response = await axios.post(`${API_BASE}/users/subscribe`, {
      user_id,
      plan_id,
    });
    return response.data;
  } catch (error: any) {
    console.error("Failed to subscribe:", error);
    throw error;
  }
};

// ===============================
// Admin APIs
// ===============================
export const fetchAdminPlans = async () => {
  try {
    const response = await axios.get(`${API_BASE}/admin/plans`);
    return response.data;
  } catch (error: any) {
    console.error("Failed to fetch admin plans:", error);
    return [];
  }
};

export const createAdminPlan = async (payload: {
  name: string;
  days: number;
  price: string;
}) => {
  try {
    const response = await axios.post(`${API_BASE}/admin/plans`, payload);
    return response.data;
  } catch (error: any) {
    console.error("Failed to create plan:", error);
    throw error;
  }
};

export const updateAdminPlan = async (plan_id: number, payload: {
  name?: string;
  days?: number;
  price?: string;
  active?: boolean;
}) => {
  try {
    const response = await axios.put(`${API_BASE}/admin/plans/${plan_id}`, payload);
    return response.data;
  } catch (error: any) {
    console.error("Failed to update plan:", error);
    throw error;
  }
};

export const deleteAdminPlan = async (plan_id: number) => {
  try {
    const response = await axios.delete(`${API_BASE}/admin/plans/${plan_id}`);
    return response.data;
  } catch (error: any) {
    console.error("Failed to delete plan:", error);
    throw error;
  }
};

// ===============================
// Fetch user subscriptions
// ===============================
export const fetchUserSubscriptions = async (user_id: number) => {
  try {
    const response = await axios.get(`${API_BASE}/users/subscriptions/${user_id}`);
    return response.data; // array of subscriptions
  } catch (error: any) {
    console.error("Failed to fetch subscriptions:", error);
    return [];
  }
};

