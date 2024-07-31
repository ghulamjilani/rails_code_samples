import {Controller} from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["houseNo", "postCode", "madrassaAddress"];

  connect() {
    console.log("Address controller connected");
    if (window.location.pathname === '/madrassas') {
      this.setInitialSelectedOption('madrassaAddress');
    } else {
      this.setInitialSelectedOption('houseNo');
      this.setInitialSelectedOption('fullAddress')
    }
  }

  setInitialSelectedOption(dropdownId) {
    if (dropdownId === 'madrassaAddress') {
      const madrassaIds = eval(document.getElementById('madrassaTable').dataset.madrassaIds);
      madrassaIds.forEach(id => {
        const madrassaDropdown = document.getElementById(`madrassaAddress${id}`)
        this.observeInitiate(madrassaDropdown);
      });
    } else {
      const dropdown = document.getElementById(dropdownId);
      this.observeInitiate(dropdown);
    }
  }

  observeInitiate(element) {
    if (element.options.length == 0) {
      const selectedAddress = element.getAttribute("data-selected-house-no");
      if (selectedAddress) {
        const option = this.createOption(selectedAddress, element);
        if (option) {
          option.selected = true;
        }
      }
    }
  }

  onHousePostCodeChange(event) {
    this.handlePostCodeChange(event, 'houseNo');
  }

  onFullPostCodeChange(event) {
    this.handlePostCodeChange(event, 'fullAddress');
  }

  onMadrassaPostCodeChange(event) {
    this.handlePostCodeChange(event, 'madrassaAddress');
  }

  handlePostCodeChange(event, targetName) {
    const postCodeElement = event.target;
    const postCode = event.target.value;
    const objId = event.target.dataset.madrassaId;

    if (postCode.length >= 5) {
      const endpoint = `/get_address?postcode=${postCode}`;
      this.makeApiCall(endpoint, targetName, postCodeElement, objId);
    } else {
      this.resetPostCodeField(postCodeElement);
    }
  }

  makeApiCall(endpoint, targetName, postCodeElement, objId) {
    let target = objId ? targetName + objId : targetName
    fetch(endpoint)
      .then(response => response.json())
      .then(data => this.handleApiResponse(data, target, postCodeElement))
      .catch(error => {
        this.resetPostCodeField(postCodeElement);
        const houseNoElement = document.getElementById(targetName);
        houseNoElement.disabled = true;
        houseNoElement.innerHTML = '';
        console.error("Error fetching data from the API:", error);
      });
  }

  updateAddressesDropdown(addresses, element) {
    element.disabled = false;

    element.innerHTML = '';
    if (addresses.length === 0) {
      const option = document.createElement('option');
      option.value = '';
      option.text = 'No Address Found';
      element.appendChild(option);
    } else {
      const defaultOption = document.createElement('option');
      defaultOption.value = '';
      defaultOption.text = '-- Select Address --';
      element.appendChild(defaultOption);

      addresses.forEach(address => {
        this.createOption(address, element);
      });
    }
  }

  createOption(address, element) {
    const option = document.createElement('option');
    option.value = address;
    option.text = address;
    element.appendChild(option);
  }

  handleApiResponse(data, targetName, postCodeElement) {
    const houseNoElement = document.getElementById(targetName);
    if (houseNoElement) {
      this.updateAddressesDropdown(data.address, houseNoElement);
      postCodeElement.classList.remove('invalid');
      postCodeElement.classList.add('valid');
    } else {
      console.error("House number element not found in the DOM");
    }
  }

  resetPostCodeField(postCodeElement) {
    postCodeElement.classList.remove('valid');
    postCodeElement.classList.add('invalid');
  }
}
