import time
from PIL import Image, ImageChops
import modules.scripts as scripts
from modules.processing import process_images, Processed, StableDiffusionProcessingImg2Img
import os

class Script(scripts.Script):
    def title(self):
        return "Load ControlNet Output from File for Masking and Inpainting"

    def show(self, is_img2img):
        return is_img2img

    def convert_segment_to_mask(self, segment_img, target_color, tolerance=70):
        mask = Image.new("L", segment_img.size, 0)
        pixels = segment_img.load()
        for y in range(segment_img.height):
            for x in range(segment_img.width):
                pixel_color = pixels[x, y][:3]
                distance = sum(abs(pixel_color[i] - target_color[i]) for i in range(3))
                if distance <= tolerance * 3:
                    mask.putpixel((x, y), 255)
        return mask

    def run(self, p: StableDiffusionProcessingImg2Img):
        try:
            # Indstil stien til ControlNet-outputfilen
            controlnet_output_path = "/home/tvup/Projects/stable-diffusion-xl-webui/outputs/cncon/controlnet_output_0_0.png"

            # Vent et øjeblik for at sikre, at filen er oprettet
            time.sleep(5)  # Vent i 5 sekunder (justér om nødvendigt)

            if not os.path.exists(controlnet_output_path):
                raise ValueError(f"ControlNet-outputfilen blev ikke fundet: {controlnet_output_path}")

            controlnet_output = Image.open(controlnet_output_path)
            controlnet_output.show(title="Loaded ControlNet Output")

            target_color = (150, 5, 61)
            tolerance = 70
            mask_image = self.convert_segment_to_mask(controlnet_output, target_color, tolerance)
            mask_image.show(title="Generated Mask")
            mask_image.save("debug_mask_output.png")
            p.image_mask = mask_image

        except Exception as e:
            raise ValueError(f"Fejl under maskegenerering: {str(e)}")

        processed = process_images(p)
        return Processed(p, processed.images, p.seed, info=processed.info)

    def ui(self, is_img2img):
        return []
