import {Controller} from "@hotwired/stimulus"

export default class extends Controller {
  form = null;

  connect() {
    this.form = this.element.querySelector('form');
    this.enable_required_validator();
    this._form_validator_by_required();
  }

  disconnect() {
    this.disable_required_validator()
  }

  enable_required_validator() {
    this.form.querySelectorAll('.required').forEach(el => {
      if (['INPUT', 'SELECT', 'TEXTAREA'].includes(el.tagName)) {
        el.addEventListener('input', this._form_validator_by_required);
      }
    })
  }

  disable_required_validator() {
    this.form.querySelectorAll('.required').forEach(el => {
      if (['INPUT', 'SELECT', 'TEXTAREA'].includes(el.tagName)) {
        el.removeEventListener('input', this._form_validator_by_required);
      }
    })
  }

  _form_validator_by_required() {
    let disabled = false;

    this.form.querySelectorAll('.required').forEach((el) => {
      if (['INPUT', 'SELECT', 'TEXTAREA'].includes(el.tagName)) {
        if (!el.value) {
          disabled = true;
          return;
        }
      }

    })

    this.form.querySelectorAll('.require-form-validation').forEach(el => {
      const element = document.getElementById('action-btn').classList;
      if (disabled == true) {
        element.remove("btn-success")
        element.add("btn-secondary")
      }

      if (disabled == false) {
        element.add("btn-success")
        element.remove("btn-secondary")
      }
      el.disabled = disabled
    })
  }
}
