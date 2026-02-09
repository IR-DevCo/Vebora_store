import React from "react";

interface StatsCardProps {
  title: string;
  value: string | number;
  icon?: React.ReactNode;
  color?: string; // رنگ بکگراند کارت یا آیکون
}

const StatsCard: React.FC<StatsCardProps> = ({ title, value, icon, color = "bg-indigo-500" }) => {
  return (
    <div className={`p-6 rounded-2xl shadow-lg flex items-center space-x-4 transition-transform transform hover:scale-105 ${color} text-white`}>
      {icon && <div className="text-3xl">{icon}</div>}
      <div className="flex flex-col">
        <span className="text-lg font-semibold">{title}</span>
        <span className="text-2xl font-bold mt-1">{value}</span>
      </div>
    </div>
  );
};

export default StatsCard;
