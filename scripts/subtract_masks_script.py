import gradio as gr
from PIL import Image, ImageChops
from modules import script_callbacks

def subtract_masks(body_mask_path, head_mask_path):
    # Åbn maskebillederne
    body_mask = Image.open(body_mask_path).convert('L')
    head_mask = Image.open(head_mask_path).convert('L')

    # Inverter hovedmasken
    head_mask_inverted = ImageChops.invert(head_mask)

    # Subtraher hovedmasken fra kropsmasken
    final_mask = ImageChops.multiply(body_mask, head_mask_inverted)

    # Returner det resulterende billede
    return final_mask

def process_images(img1, img2):
    final_mask = subtract_masks(img1, img2)
    return final_mask

def on_ui_tabs():
    with gr.Blocks() as demo:
        img1 = gr.Image(label="Body Mask", type="filepath")
        img2 = gr.Image(label="Head Mask", type="filepath")
        output = gr.Image(label="Final Mask")
        btn = gr.Button("Subtract Masks")
        btn.click(fn=process_images, inputs=[img1, img2], outputs=output)
    return [(demo, "Subtract Masks", "subtract_masks")]

# Tilføj denne linje for at importere script_callbacks korrekt
script_callbacks.on_ui_tabs(on_ui_tabs)
