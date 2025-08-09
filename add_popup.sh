#!/usr/bin/env bash
set -euo pipefail

BRANCH="$(git rev-parse --abbrev-ref HEAD || echo main)"
STEP="start"
trap 'echo "❌ Failed during: $STEP"; exit 1' ERR

STEP="sanity checks"
git rev-parse --is-inside-work-tree >/dev/null 2>&1 || { echo "Run from repo root."; exit 1; }
mkdir -p sections

STEP="write section"
cat > sections/sms-optin-popup.liquid <<'LIQUID'
{% comment %}
  SMS Opt-in Popup (Barry's Pro Cleaning)
  - Accessible dialog (role="dialog", ESC to close)
  - Delay before showing
  - Cooldown (days) using localStorage timestamp
  - Option to show only on home page
{% endcomment %}

{%- assign is_home = request.page_type == 'index' -%}
{%- assign home_only = section.settings.home_only -%}

{%- if home_only and is_home == false -%}
  {#-- Do not render on non-home pages when home_only is true --#}
{%- else -%}
<div id="sms-optin" class="sms-optin" role="dialog" aria-modal="true" aria-labelledby="sms-optin-title" hidden>
  <button class="sms-optin__close" aria-label="Close dialog" type="button">×</button>
  <h3 id="sms-optin-title" class="h4">{{ section.settings.heading | default: "Get cleaning tips & offers" }}</h3>

  <form method="post" action="/contact#ContactFooter" accept-charset="UTF-8">
    <input type="hidden" name="form_type" value="contact">
    <input type="text" name="contact[name]" placeholder="Your name" required>
    <input type="tel" name="contact[phone]" placeholder="Mobile number" required>
    <input type="hidden" name="contact[body]" value="SMS opt-in via popup">
    <button class="button button--primary">{{ section.settings.button | default: "Subscribe" }}</button>
  </form>

  {%- if section.settings.consent != blank -%}
    <p class="sms-optin__fineprint">{{ section.settings.consent }}</p>
  {%- endif -%}
</div>

<style>
  .sms-optin{ position:fixed; right:16px; bottom:16px; width:320px; z-index:50; background:#fff; border:1px solid #e5e7eb; border-radius:12px; padding:16px; box-shadow:0 10px 24px rgba(0,0,0,.08) }
  .sms-optin input{ width:100%; margin-bottom:8px }
  .sms-optin__close{ position:absolute; top:6px; right:8px; background:transparent; border:none; font-size:20px; cursor:pointer; line-height:1 }
  .sms-optin__fineprint{ font-size:.75rem; color:#6b7280; margin-top:8px }
  @media (max-width: 480px){ .sms-optin{ width: calc(100% - 24px); right:12px; left:12px } }
</style>

<script>
(function(){
  var SETTINGS = {
    delayMs: ({{ section.settings.delay | default: 5 }} * 1000),
    cooldownDays: {{ section.settings.cooldown_days | default: 14 }},
    storageKey: 'sms_optin_closed_v2'
  };

  function now(){ return Date.now(); }
  function getTs(){ try{ return parseInt(localStorage.getItem(SETTINGS.storageKey) || '0', 10); } catch(e){ return 0; } }
  function setTs(){ try{ localStorage.setItem(SETTINGS.storageKey, String(now())); } catch(e){} }

  function isCoolingDown(){
    var last = getTs();
    if(!last) return false;
    var ms = SETTINGS.cooldownDays * 24 * 60 * 60 * 1000;
    return (now() - last) < ms;
  }

  function show(){
    var el = document.getElementById('sms-optin');
    if(!el) return;
    el.hidden = false;

    // focus management (basic)
    var firstInput = el.querySelector('input,button,select,textarea,a[href]');
    if(firstInput) firstInput.focus();

    // ESC closes
    document.addEventListener('keydown', onEsc);
  }

  function hide(){
    var el = document.getElementById('sms-optin');
    if(!el) return;
    el.hidden = true;
    setTs();
    document.removeEventListener('keydown', onEsc);
  }

  function onEsc(e){
    if(e.key === 'Escape'){ hide(); }
  }

  // close button
  document.addEventListener('click', function(e){
    if(e.target && e.target.classList.contains('sms-optin__close')) hide();
  });

  // don't show if cooldown active
  if(isCoolingDown()) return;

  // show after delay
  setTimeout(show, SETTINGS.delayMs);
})();
</script>

{% schema %}
{
  "name": "SMS opt-in popup",
  "settings":[
    { "type":"text", "id":"heading", "label":"Heading", "default":"Get cleaning tips & offers" },
    { "type":"text", "id":"button", "label":"Button label", "default":"Subscribe" },
    { "type":"range", "id":"delay", "label":"Delay before showing (seconds)", "min":1, "max":30, "step":1, "default":5 },
    { "type":"range", "id":"cooldown_days", "label":"Cooldown days (re-show after)", "min":1, "max":60, "step":1, "default":14 },
    { "type":"checkbox", "id":"home_only", "label":"Show only on home page", "default":true },
    { "type":"textarea", "id":"consent", "label":"Consent text", "default":"You agree to receive promotional messages from Barry’s Pro Cleaning LLC. Msg frequency varies. Msg & data rates may apply. Reply STOP to end or HELP for help." }
  ],
  "presets":[ { "name":"SMS opt-in popup" } ]
}
{% endschema %}
LIQUID
{% endif %}
