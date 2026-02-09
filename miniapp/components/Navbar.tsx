import React from "react";
import Link from "next/link";
import { useRouter } from "next/router";
import { Bell, LogOut, User } from "lucide-react";

interface NavbarProps {
  username: string;
  isAdmin: boolean;
}

const Navbar: React.FC<NavbarProps> = ({ username, isAdmin }) => {
  const router = useRouter();

  const handleLogout = () => {
    // حذف توکن از localStorage یا هر روش احراز هویت
    localStorage.removeItem("token");
    router.push("/login");
  };

  return (
    <nav className="bg-gradient-to-r from-indigo-500 via-purple-500 to-pink-500 p-4 shadow-md flex justify-between items-center text-white">
      <div className="flex items-center space-x-4">
        <h1 className="text-xl font-bold">🌟 Vebora Store</h1>
        <Link href="/">
          <span className="hover:underline cursor-pointer">🏠 داشبورد</span>
        </Link>
        {isAdmin && (
          <Link href="/admin">
            <span className="hover:underline cursor-pointer">👑 پنل ادمین</span>
          </Link>
        )}
      </div>

      <div className="flex items-center space-x-4">
        <span className="flex items-center space-x-1">
          <User size={18} /> <span>{username}</span>
        </span>
        <button
          onClick={handleLogout}
          className="flex items-center space-x-1 hover:text-gray-200"
        >
          <LogOut size={18} /> <span>خروج</span>
        </button>
        <button className="relative hover:text-gray-200">
          <Bell size={18} />
          <span className="absolute -top-1 -right-2 bg-red-500 rounded-full text-xs w-4 h-4 flex items-center justify-center">
            3
          </span>
        </button>
      </div>
    </nav>
  );
};

export default Navbar;
