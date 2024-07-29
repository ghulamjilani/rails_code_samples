import {Controller} from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ['lessonSelect', 'lineSelect', 'boxSelect', 'sabaqInput', 'paraSelect', 'rukuSelect', 'feedbackSelect', 'bookSelect', 'pageSelect'];
  connect() {
    this.showPreviouslySelectedValues();
  }

  updateSabaq() {
    const currentForm = this.currentForm();

    currentForm === 'qaidah' ? this.sabaqForQaidah() : this.sabaqForNonQaidah();
  }

  sabaqForNonQaidah() {
    const currentForm = this.currentForm();

    currentForm === 'fiqh' ? this.sabaqForFiqh() : this.sabaqForNazirah()
  }

  showPreviouslySelectedValues() {
    const currentForm = this.currentForm();

    if (currentForm === 'nazirah' || currentForm === 'hifz') {
      const [para, ruku, line] = this.sabaqInputTarget.value.split(',');

      this.paraSelectTarget.value = para || '';
      this.rukuSelectTarget.value = ruku || '';
      this.lineSelectTarget.value = line || '';
    } else if (currentForm === 'fiqh') {
      const [book, page, dua] = this.sabaqInputTarget.value.split(',');

      this.bookSelectTarget.value = book || '';
      this.pageSelectTarget.value = page || '';
      this.lineSelectTarget.value = dua || '';
    } else {

      const [lesson, line, box] = this.sabaqInputTarget.value.split(',');

      this.lessonSelectTarget.value = lesson || '';
      this.lineSelectTarget.value = line || '';
      this.boxSelectTarget.value = box || '';
    }
  }

  currentForm() {
    const parent = this.findParentWithDataset(this.lineSelectTarget, 'subject')
    const currentForm = parent.dataset.subject;
    return currentForm;
  }

  findParentWithDataset(element, datasetKey) {
    let parent = element.parentElement;
    while (parent) {
      if (parent.dataset[datasetKey] !== undefined) {
        return parent;
      }
      parent = parent.parentElement;
    }
    return null;
  }

  sabaqForNazirah() {
    const para = this.paraSelectTarget.value;
    const ruku = this.rukuSelectTarget.value;
    const line = this.lineSelectTarget.value;

    const sabaqInput = [para, ruku, line].join(',');
    this.sabaqInputTarget.value = sabaqInput;
  }

  sabaqForQaidah() {
    const lesson = this.lessonSelectTarget.value;
    const line = this.lineSelectTarget.value;
    const box = this.boxSelectTarget.value;

    const sabaqInput = [lesson, line, box].join(',');
    this.sabaqInputTarget.value = sabaqInput;
  }

  sabaqForFiqh() {
    const book = this.bookSelectTarget.value;
    const page = this.pageSelectTarget.value;
    const dua = this.lineSelectTarget.value;

    const sabaqInput = [book, page, dua].join(',');
    this.sabaqInputTarget.value = sabaqInput;
  }

  toggleOtherFeeback() {
    const feedback = this.feedbackSelectTarget.value;
    const parent = this.findParentWithDataset(this.feedbackSelectTarget, 'studentId')
    const stdId = parent.dataset.studentId;
    const container = document.getElementById(`other_feedback_${stdId}`);

    if (feedback === 'Other') {
      container.classList.remove('d-none');
    } else {
      container.classList.add('d-none');
    }
  }
}
