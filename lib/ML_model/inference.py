from diffusers import StableDiffusionPipeline, DDIMScheduler
import torch

device = "cpu"
model_id = "runwayml/stable-diffusion-v1-5"

scheduler = DDIMScheduler.from_pretrained(model_id, subfolder="scheduler")
pipeline = StableDiffusionPipeline.from_pretrained(
    model_id,
    scheduler=scheduler,
    torch_dtype=torch.float16
).to(device)

# comment out the line if xformers is not installed
# pipeline.enable_xformers_memory_efficient_attention()

generator = torch.Generator(device=device).manual_seed(42)
prompt = "Natural landscape in anime style illustration"

# image generation
image = pipeline(prompt, generator=generator).images[0]
image.save("image_512.png")