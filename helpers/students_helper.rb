# frozen_string_literal: true

module StudentsHelper
  def generate_options(base_options, additional_options)
    base_options + Array(additional_options).map(&:to_s)
  end

  def number_options
    generate_options([], (1..6))
  end

  def lesson_options
    generate_options(number_options, (7..22))
  end

  def line_options
    generate_options(lesson_options, (23..29))
  end

  def para_options
    generate_options(line_options, 30)
  end

  def ruku_options
    generate_options(para_options, (31..40))
  end

  def feedback_options
    ['Sabak/sabqi/Manzil has been satisfactory. Improvement is required',
     'He has tried very hard and all credit is due to him for his effort',
     'Sabak/sabqi/ Manzil was good and he has done really well. Well done',
     'Rules were below satisfactory and need to be learnt',
     'He does not always apply the rules to his recitation.',
     'He has excelled once again. Brilliant all around',
     'Improvements are required across all areas.',
     'He has done well but can be even better. More revision is required on a regular basis',
     'Other']
  end

  def current_score(student)
    student.scores.for_today.first
  end

  def hand_book_url(hand_book)
    hand_book.present? ? hand_book.attachment_url : '/madrassa-tul-madinah-parent-handbook.pdf'
  end

  def sabaqi_form_field(form, student)
    subject = student.current_subject
    return unless subject.present?

    subject.name.eql?('Hifz') ? render_hifz_form_field(form) : render_non_hifz_form_field(form)
  end

  def manzil_form_field(form, student)
    subject = student.current_subject
    return unless subject.present?

    content_tag(:div, class: 'form-group') do
      concat form.label(:manzil, 'Manzil', class: 'form-label')
      concat form.text_field(:manzil, class: 'form-control form-control-md rounded-0',
                             required: true, placeholder: manzil_placeholder(subject.name))
      concat manzil_hint_list(subject.name)
    end
  end

  def sabaq_form_field(form, student)
    student.current_subject&.name.eql?('Qaidah') ? render_qaidah_specific_sabaq(form) : render_non_qaidah_specific_sabaq(form, student)
  end

  def hide_if_other_feedback(form)
    form.object_id.present? && form.object.feedback.eql?('Other') ? '' : 'd-none'
  end

  def choose_feedback(score)
    score.feedback.eql?('Other') ? score.other_feedback : score.feedback
  end

  private

  def render_hifz_form_field(form)
    content_tag(:div, class: 'form-group') do
      concat form.label(:sabaq, 'Sabaqi', class: 'form-label')
      concat form.text_field(:sabaqi, class: 'form-control form-control-md rounded-0 py-2',
                             required: true, placeholder: 'Input the ‘alternating ¼’ that has been read')
    end
  end

  def render_non_hifz_form_field(form)
    content_tag(:div, class: 'form-check') do
      concat form.check_box(:sabaqi, class: 'form-check-input')
      concat form.label(:sabaqi, 'Sabaqi', class: 'form-label')
    end
  end

  def manzil_placeholder(subject)
    if subject.eql?('Qaidah')
      'Input the lesson number/s'
    elsif subject.eql?('Nazirah')
      'Input the Para + Ruku number/s'
    elsif subject.eql?('Fiqh')
      'Input the Book name + Page number + Dua number'
    else
      'Input Details'
    end
  end

  def manzil_hint_list(subject)
    return if subject.eql?('Qaidah') || subject.eql?('Fiqh')

    content_tag(:div, class: 'mt-2') do
      concat content_tag(:p, 'Hint:', class: 'text-success mb-0')
      concat(content_tag(:ul, class: 'text-muted') do
        subject.eql?('Hifz') ? manzil_hint_for_hifz(&method(:concat)) : manzil_hint_for_nazirah(&method(:concat))
      end)
    end
  end

  def manzil_hint_for_nazirah
    concat content_tag(:li, '30th Para, 1st Ruku = 30/1')
    concat content_tag(:li, '1st Para, 3rd + 4th Ruku = 1/4 (just write the last Ruku read)')
  end

  def manzil_hint_for_hifz
    concat content_tag(:li, '30th Para 1st half = 30 1/2')
    concat content_tag(:li, '30th Para 2nd half = 30 2/2')
    concat content_tag(:li, '1st Para 1st, 2nd + 3rd ¼ = 1 ¾ (just write the last ¼ read)')
  end

  def render_qaidah_specific_sabaq(form)
    content_tag(:div, class: 'row gx-1 gy-2', data: { controller: 'scores' }) do
      concat lesson_select
      concat line_select
      concat box_select
      concat form.hidden_field(:sabaq, data: { 'scores-target': 'sabaqInput' })
    end
  end

  def lesson_select
    content_tag(:div, class: 'col-md-4') do
      select_tag(
        'lesson_no',
        options_for_select(lesson_options),
        prompt: '-- Lesson No. --',
        class: 'form-control form-control-md rounded-0',
        required: true,
        data: { action: 'change->scores#updateSabaq', 'scores-target': 'lessonSelect' }
      )
    end
  end

  def line_select
    content_tag(:div, class: 'col-md-4') do
      select_tag(
        'line_no',
        options_for_select(line_options),
        prompt: '-- Line No. --',
        class: 'form-control form-control-md rounded-0',
        required: true,
        data: { action: 'change->scores#updateSabaq', 'scores-target': 'lineSelect' }
      )
    end
  end

  def ayat_no_field
    content_tag(:div, class: 'col-md-4') do
      number_field_tag(
        'line_no',
         nil,
         placeholder: '-- Ayat No. --',
         class: 'form-control form-control-md rounded-0',
         required: true,
         min: 1,
         data: { action: 'change->scores#updateSabaq', 'scores-target': 'lineSelect' }
      )
    end
  end

  def box_select
    content_tag(:div, class: 'col-md-4') do
      select_tag(
        'box_no',
        options_for_select(number_options),
        prompt: '-- Box No. --',
        class: 'form-control form-control-md rounded-0',
        required: true,
        data: { action: 'change->scores#updateSabaq', 'scores-target': 'boxSelect' }
      )
    end
  end

  def render_non_qaidah_specific_sabaq(form, student)
    student.current_subject.name.eql?('Fiqh') ? fiqh_related_sabaq(form) : non_fiqh_related_sabaq(form)
  end

  def fiqh_related_sabaq(form)
    content_tag(:div, class: 'row gx-1 gy-2', data: { controller: 'scores' }) do
      concat book_select
      concat page_no_select
      concat dua_no_select
      concat form.hidden_field(:sabaq, data: { 'scores-target': 'sabaqInput' })
    end
  end

  def non_fiqh_related_sabaq(form)
    content_tag(:div, class: 'row gx-1 gy-2', data: { controller: 'scores' }) do
      concat para_select
      concat ruku_select
      concat ayat_no_field
      concat form.hidden_field(:sabaq, data: { 'scores-target': 'sabaqInput' })
    end
  end

  def book_select
    content_tag(:div, class: 'col-md-4') do
      select_tag(
        'book_name',
        options_for_select(['Laws of Salah',
                            'Quranic Wonders - Part 2',
                            'Proper Sunni Beliefs and Other Beliefs',
                            'Seerat-e-Mustafa (Blessed Seerah of Blessed Mustafa P.B.U.H)'
                           ]),
        prompt: '-- Book Name --',
        class: 'form-control form-control-md rounded-0',
        required: true,
        data: { action: 'change->scores#updateSabaq', 'scores-target': 'bookSelect' }
      )
    end
  end

  def page_no_select
    content_tag(:div, class: 'col-md-4') do
      select_tag(
        'page_no',
        options_for_select(generate_options([], (1..250))),
        prompt: '-- Page No. --',
        class: 'form-control form-control-md rounded-0',
        required: true,
        data: { action: 'change->scores#updateSabaq', 'scores-target': 'pageSelect' }
      )
    end
  end

  def dua_no_select
    content_tag(:div, class: 'col-md-4') do
      select_tag(
        'dua_no',
        options_for_select(generate_options([], (1..20))),
        prompt: '-- Dua No. --',
        class: 'form-control form-control-md rounded-0',
        required: true,
        data: { action: 'change->scores#updateSabaq', 'scores-target': 'lineSelect' }
      )
    end
  end

  def para_select
    content_tag(:div, class: 'col-md-4') do
      select_tag(
        'para_no',
        options_for_select(para_options),
        prompt: '-- Para No. --',
        class: 'form-control form-control-md rounded-0',
        required: true,
        data: { action: 'change->scores#updateSabaq', 'scores-target': 'paraSelect' }
      )
    end
  end

  def ruku_select
    content_tag(:div, class: 'col-md-4') do
      select_tag(
        'ruku_no',
        options_for_select(ruku_options),
        prompt: '-- Ruku No. --',
        class: 'form-control form-control-md rounded-0',
        required: true,
        data: { action: 'change->scores#updateSabaq', 'scores-target': 'rukuSelect' }
      )
    end
  end

  def formatted_sabaq(sabaq, subject)
    lesson, line, box = sabaq.split(',')

    if subject.eql?('Qaidah')
      "Lesson no #{lesson}, Line no #{line}, Box no #{box}"
    elsif subject.eql?('Fiqh')
      "Book name #{lesson}, Page number #{line}, Dua number #{box}"
    else
      "Para No #{lesson}, Ruku number #{line}, Ayat number #{box}"
    end
  end

  def convert_sabaqi_status(status)
    case status
    when '0'
      'No'
    when '1'
      'Yes'
    else
      status
    end
  end

  def leave_class(student)
    student.is_on_leave_today? ? 'pale-green' : ''
  end
end
