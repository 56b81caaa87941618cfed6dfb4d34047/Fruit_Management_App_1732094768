import React from 'react';

const Header: React.FC = () => {
  return (
    <header className="bg-blue-500 text-white p-4 w-full h-full bg-cover bg-center" style={{backgroundImage: "url('https://raw.githubusercontent.com/56b81caaa87941618cfed6dfb4d34047/Fruit_Management_App_1732094768/main/src/assets/images/f2a6e59fc4f54f1c8e42d997e04f2bb6.jpeg')"}}> {/* Full width and height with background image */}
      <div className="container mx-auto flex justify-between items-center h-full">
        <div className="text-2xl font-bold">FruitTracker Pro</div>
        <div className="text-3xl font-extrabold">WAA</div>
      </div>
    </header>
  );
};

export { Header as component };