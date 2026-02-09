import React, { useEffect, useState } from "react";
import {
  fetchAdminPlans,
  createAdminPlan,
  updateAdminPlan,
  deleteAdminPlan,
} from "../services/api";
import PlanCard from "../components/PlanCard";
import toast, { Toaster } from "react-hot-toast";

interface Plan {
  id: number;
  name: string;
  days: number;
  price: string;
  active: boolean;
}

const AdminPage: React.FC = () => {
  const [plans, setPlans] = useState<Plan[]>([]);
  const [loading, setLoading] = useState<boolean>(true);
  const [newPlan, setNewPlan] = useState({ name: "", days: 0, price: "" });

  const loadPlans = async () => {
    setLoading(true);
    const data = await fetchAdminPlans();
    setPlans(data);
    setLoading(false);
  };

  useEffect(() => {
    loadPlans();
  }, []);

  const handleCreate = async () => {
    if (!newPlan.name || !newPlan.days || !newPlan.price) {
      toast.error("⚠️ All fields are required");
      return;
    }
    try {
      await createAdminPlan(newPlan);
      toast.success("✅ Plan created");
      setNewPlan({ name: "", days: 0, price: "" });
      loadPlans();
    } catch (error) {
      toast.error("⚠️ Failed to create plan");
    }
  };

  const handleDelete = async (id: number) => {
    try {
      await deleteAdminPlan(id);
      toast.success("✅ Plan deleted");
      loadPlans();
    } catch (error) {
      toast.error("⚠️ Failed to delete plan");
    }
  };

  const handleToggleActive = async (plan: Plan) => {
    try {
      await updateAdminPlan(plan.id, { active: !plan.active });
      toast.success("✅ Plan updated");
      loadPlans();
    } catch (error) {
      toast.error("⚠️ Failed to update plan");
    }
  };

  return (
    <div className="min-h-screen bg-gray-100 flex flex-col items-center p-6">
      <Toaster position="top-right" />
      <h1 className="text-3xl font-bold mb-6">🛠 Admin Panel</h1>

      {/* Create New Plan */}
      <div className="bg-white p-6 rounded-2xl shadow-lg mb-6 w-full max-w-xl">
        <h2 className="text-xl font-bold mb-4">➕ Create New Plan</h2>
        <input
          type="text"
          placeholder="Plan Name"
          className="border p-2 rounded w-full mb-2"
          value={newPlan.name}
          onChange={(e) => setNewPlan({ ...newPlan, name: e.target.value })}
        />
        <input
          type="number"
          placeholder="Days"
          className="border p-2 rounded w-full mb-2"
          value={newPlan.days}
          onChange={(e) => setNewPlan({ ...newPlan, days: parseInt(e.target.value) })}
        />
        <input
          type="text"
          placeholder="Price"
          className="border p-2 rounded w-full mb-2"
          value={newPlan.price}
          onChange={(e) => setNewPlan({ ...newPlan, price: e.target.value })}
        />
        <button
          onClick={handleCreate}
          className="bg-green-500 text-white font-bold py-2 px-4 rounded hover:bg-green-600 transition-colors"
        >
          Create Plan
        </button>
      </div>

      {/* List Existing Plans */}
      <div className="flex flex-wrap justify-center">
        {plans.map((plan) => (
          <div
            key={plan.id}
            className={`rounded-2xl p-6 shadow-lg w-64 m-4 ${
              plan.active
                ? "bg-gradient-to-r from-blue-500 to-purple-600 text-white"
                : "bg-gray-300 text-gray-700"
            }`}
          >
            <h2 className="text-xl font-bold mb-2">{plan.name}</h2>
            <p>📅 Days: {plan.days}</p>
            <p>💰 Price: {plan.price}</p>
            <p>Status: {plan.active ? "✅ Active" : "❌ Inactive"}</p>
            <div className="flex justify-between mt-4">
              <button
                onClick={() => handleToggleActive(plan)}
                className="bg-yellow-400 text-white px-2 py-1 rounded hover:bg-yellow-500"
              >
                Toggle
              </button>
              <button
                onClick={() => handleDelete(plan.id)}
                className="bg-red-500 text-white px-2 py-1 rounded hover:bg-red-600"
              >
                Delete
              </button>
            </div>
          </div>
        ))}
      </div>
    </div>
  );
};

export default AdminPage;
