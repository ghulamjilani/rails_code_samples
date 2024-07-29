import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ['imagePreview', 'fileInput'];

  connect() {
    this.fileInputTargets.forEach((input) => {
      this.showImagePreview(input);
      input.addEventListener("change", this.previewImage.bind(this));
    });
  }

  disconnect() {
    this.fileInputTargets.forEach((input) => {
      input.removeEventListener("change", this.previewImage.bind(this));
    });

    if (this.hasFileInputTarget) {
      this.fileInputTarget.removeEventListener("change", this.previewImage);
    }
  }

  previewImage(event) {
    const input = event.target;
    const imagePreview = input.closest(".circular-file-input").querySelector("img[data-managers-target='imagePreview']");

    if (input.files && input.files[0]) {
      const reader = new FileReader();

      reader.onload = (e) => {
        if (imagePreview) {
          imagePreview.src = e.target.result;
          imagePreview.style.display = "unset";
          const svgElement = input.closest(".circular-file-input").querySelector(".circle svg");
          const headingElement = input.closest(".circular-file-input").querySelector(".circle h6");

          if (svgElement && headingElement) {
            svgElement.style.display = "none";
            headingElement.style.display = "none";
          }
          imagePreview.parentElement.classList.add("has-image");
        }
      };

      reader.readAsDataURL(input.files[0]);
    }
  }

  showImagePreview(input) {
    const imagePreview = this.getImagePreview(input);
    if (imagePreview && imagePreview.dataset.imageUrl) {
      imagePreview.src = imagePreview.dataset.imageUrl;
      imagePreview.style.display = "unset";
      const svgElement = input.closest(".circular-file-input").querySelector(".circle svg");
      const headingElement = input.closest(".circular-file-input").querySelector(".circle h6");

      if (svgElement && headingElement) {
        svgElement.style.display = "none";
        headingElement.style.display = "none";
      }
      imagePreview.parentElement.classList.add("has-image");
    }
  }

  getImagePreview(input) {
    return input.closest(".circular-file-input").querySelector("img[data-managers-target='imagePreview']");
  }
}
