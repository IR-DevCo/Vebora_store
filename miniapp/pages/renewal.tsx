import React, { useEffect, useState } from "react";
import { fetchUserSubscriptions, fetchPlans, subscribeUser } from "../services/api";
import toast, { Toaster } from "react-hot-toast";
import PlanCard from "../components/PlanCard";

interface Subscription {
  plan_name: string;
  start_date: string;
  end_date: string;
  active: boolean;
}

interface Plan {
  id: number;
  name: string;
  days: number;
  price: string;
}

const RenewalPage: React.FC = () => {
  const [subscriptions, setSubscriptions] = useState<Subscription[]>([]);
  const [plans, setPlans] = useState<Plan[]>([]);
  const [loading, setLoading] = useState<boolean>(true);

  // برای نمونه، user_id فرضی، در پروژه واقعی از auth بگیرید
  const user_id = 1;

  useEffect(() => {
    const loadData = async () => {
      setLoading(true);
      try {
        const subs = await fetchUserSubscriptions(user_id);
        const availablePlans = await fetchPlans();
        setSubscriptions(subs);
        setPlans(availablePlans);
      } catch (error) {
        toast.error("⚠️ Failed to load data");
      } finally {
        setLoading(false);
      }
    };
    loadData();
  }, []);

  const handleRenew = async (planId: number) => {
    try {
      await subscribeUser(user_id, planId);
      toast.success("✅ Subscription renewed successfully!");
      const subs = await fetchUserSubscriptions(user_id);
      setSubscriptions(subs);
    } catch (error) {
      toast.error("⚠️ Renewal failed");
    }
  };

  return (
    <div className="min-h-screen bg-gray-100 flex flex-col items-center p-6">
      <Toaster position="top-right" />
      <h1 className="text-3xl font-bold mb-6">🔄 Renew Your Subscription</h1>

      {loading ? (
        <p>Loading subscriptions and plans...</p>
      ) : (
        <>
          <h2 className="text-xl font-semibold mb-4">Your Subscriptions:</h2>
          {subscriptions.length === 0 ? (
            <p>You have no subscriptions.</p>
          ) : (
            <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4 mb-6">
              {subscriptions.map((sub, index) => (
                <div
                  key={index}
                  className={`rounded-2xl p-6 shadow-lg w-80 ${
                    sub.active
                      ? "bg-gradient-to-r from-green-400 to-green-600 text-white"
                      : "bg-gray-300 text-gray-700"
                  }`}
                >
                  <h3 className="text-lg font-bold">{sub.plan_name}</h3>
                  <p>📅 Start: {new Date(sub.start_date).toLocaleDateString()}</p>
                  <p>📅 End: {new Date(sub.end_date).toLocaleDateString()}</p>
                  <p>Status: {sub.active ? "✅ Active" : "❌ Inactive"}</p>
                </div>
              ))}
            </div>
          )}

          <h2 className="text-xl font-semibold mb-4">Available Plans for Renewal:</h2>
          <div className="flex flex-wrap justify-center">
            {plans.map((plan) => (
              <PlanCard
                key={plan.id}
                id={plan.id}
                name={plan.name}
                days={plan.days}
                price={plan.price}
                onSubscribe={handleRenew}
              />
            ))}
          </div>
        </>
      )}
    </div>
  );
};

export default RenewalPage;
