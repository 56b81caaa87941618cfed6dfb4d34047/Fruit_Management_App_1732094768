import React from 'react';

const Footer: React.FC = () => {
  return (
    <footer className="bg-gray-800 text-white p-8 w-full h-full"> {/* Full width and height */}
      <div className="container mx-auto h-full">
        <div className="flex flex-col items-center justify-between h-full">
          
          {/* FOOTER COPY */}
          <div className="w-full md:w-1/3 mb-6 md:mb-0 text-center">
            <h3 className="text-xl font-bold mb-2">FruitTracker Pro</h3>
            <p className="text-gray-400">© 2023 FruitTracker Pro. Keeping your fruits fresh and your business fruitful.</p>
          </div>

          {/* IMAGE */}
          {/* IMAGE */}
          <div className="w-full md:w-1/3 mb-6 md:mb-0 flex justify-center">
            <img src="https://raw.githubusercontent.com/56b81caaa87941618cfed6dfb4d34047/Fruit_Management_App_1732094768/main/src/assets/images/0bd1a497ab04459d887c23a4f50d6d9a.jpeg" alt="Footer Image" className="max-w-full h-auto" />
          </div>

          {/* SOCIALS */}
          <div className="w-full md:w-1/3 mb-6 md:mb-0 text-center">
            <h4 className="text-lg font-semibold mb-2">Follow Us</h4>
            <div className="flex justify-center space-x-4">
              <a href="#" className="text-gray-400 hover:text-white">Facebook</a>
              <a href="#" className="text-gray-400 hover:text-white">Twitter</a>
              <a href="#" className="text-gray-400 hover:text-white">Instagram</a>
            </div>
          </div>
        </div>
        </div>
    </footer>
  );
};

export { Footer as component };