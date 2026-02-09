import React, { useEffect, useState } from "react";
import PlanCard from "../components/PlanCard";
import { fetchPlans, subscribeUser } from "../services/api";
import toast, { Toaster } from "react-hot-toast";

interface Plan {
  id: number;
  name: string;
  days: number;
  price: string;
}

const IndexPage: React.FC = () => {
  const [plans, setPlans] = useState<Plan[]>([]);
  const [loading, setLoading] = useState<boolean>(true);

  // برای سادگی، user_id فرضی، در ریل پروژه باید از auth بگیریم
  const user_id = 1;

  useEffect(() => {
    const loadPlans = async () => {
      setLoading(true);
      const data = await fetchPlans();
      setPlans(data);
      setLoading(false);
    };
    loadPlans();
  }, []);

  const handleSubscribe = async (planId: number) => {
    try {
      await subscribeUser(user_id, planId);
      toast.success("✅ Subscription successful!");
    } catch (error: any) {
      toast.error("⚠️ Subscription failed!");
    }
  };

  return (
    <div className="min-h-screen bg-gray-100 flex flex-col items-center p-6">
      <Toaster position="top-right" />
      <h1 className="text-3xl font-bold mb-6">📦 Vebora Store Plans</h1>

      {loading ? (
        <p>Loading plans...</p>
      ) : plans.length === 0 ? (
        <p>No active plans available.</p>
      ) : (
        <div className="flex flex-wrap justify-center">
          {plans.map((plan) => (
            <PlanCard
              key={plan.id}
              id={plan.id}
              name={plan.name}
              days={plan.days}
              price={plan.price}
              onSubscribe={handleSubscribe}
            />
          ))}
        </div>
      )}
    </div>
  );
};

export default IndexPage;
