from PIL import Image
import os

def create_checkerboard():
    size = 40
    square_size = 20
    
    img = Image.new('RGBA', (size, size), (255, 255, 255, 0))
    
    for y in range(0, size, square_size):
        for x in range(0, size, square_size):
            if (x // square_size + y // square_size) % 2 == 0:
                for i in range(square_size):
                    for j in range(square_size):
                        if x + i < size and y + j < size:
                            img.putpixel((x + i, y + j), (230, 230, 230, 255))
            else:
                for i in range(square_size):
                    for j in range(square_size):
                        if x + i < size and y + j < size:
                            img.putpixel((x + i, y + j), (255, 255, 255, 255))
    
    output_dir = 'assets/images'
    os.makedirs(output_dir, exist_ok=True)
    
    img.save(f'{output_dir}/checkerboard.png')
    print(f'Checkerboard pattern created: {output_dir}/checkerboard.png')

if __name__ == '__main__':
    create_checkerboard()