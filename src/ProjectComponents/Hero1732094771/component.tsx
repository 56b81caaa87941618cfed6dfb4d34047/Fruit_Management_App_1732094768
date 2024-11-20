import React, { useState } from 'react';

const Hero: React.FC = () => {
  const [favoriteFruit, setFavoriteFruit] = useState<string>('');

  const handleSubmit = (e: React.FormEvent<HTMLFormElement>) => {
    e.preventDefault();
    console.log('Favorite fruit:', favoriteFruit);
  };

  return (
    <div className="bg-black py-16 text-white w-full h-full">
      <div className="container mx-auto px-4 flex flex-col md:flex-row items-center h-full">
        <div className="md:w-1/2 mb-8 md:mb-0">
          <h1 className="text-4xl font-bold mb-4">Revolutionize Your Fruit Inventory Management</h1>
          <p className="text-xl mb-6">Effortlessly track, organize, and optimize your fruit stock with our intuitive app</p>
        </div>
        <div className="md:w-1/2">
          <form onSubmit={handleSubmit} className="bg-gray-800 p-6 rounded-lg shadow-md">
            <h2 className="text-2xl font-bold mb-4">Choose Your Favorite Fruit</h2>
            <div className="mb-4">
              <label htmlFor="fruitSelect" className="block text-sm font-medium mb-2">
                Select a fruit:
              </label>
              <select
                id="fruitSelect"
                value={favoriteFruit}
                onChange={(e) => setFavoriteFruit(e.target.value)}
                className="w-full p-2 rounded-md bg-gray-700 text-white"
              >
                <option value="">Select a fruit</option>
                <option value="apple">Apple</option>
                <option value="banana">Banana</option>
                <option value="orange">Orange</option>
                <option value="strawberry">Strawberry</option>
              </select>
            </div>
            <button
              type="submit"
              className="w-full bg-green-500 hover:bg-green-600 text-white font-bold py-2 px-4 rounded-lg transition duration-300"
            >
              <i className='bx bx-check mr-2'></i>
              Submit
            </button>
          </form>
        </div>
      </div>
    </div>
  );
};

export { Hero as component }