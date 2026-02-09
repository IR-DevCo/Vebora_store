import React from "react";

interface PlanCardProps {
  id: number;
  name: string;
  days: number;
  price: string;
  onSubscribe: (planId: number) => void;
}

const PlanCard: React.FC<PlanCardProps> = ({ id, name, days, price, onSubscribe }) => {
  return (
    <div className="bg-gradient-to-r from-purple-500 to-pink-500 rounded-2xl shadow-lg p-6 text-white m-4 w-64 transition-transform transform hover:scale-105">
      <h2 className="text-xl font-bold mb-2">{name}</h2>
      <p className="mb-1">📅 Duration: {days} days</p>
      <p className="mb-4">💰 Price: {price}</p>
      <button
        className="bg-white text-purple-600 font-semibold py-2 px-4 rounded-full hover:bg-purple-100 transition-colors"
        onClick={() => onSubscribe(id)}
      >
        Subscribe
      </button>
    </div>
  );
};

export default PlanCard;
