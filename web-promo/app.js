/* ==========================================================================
   BobKasir Promotional Landing Page JavaScript
   Interactivity: Mobile Navigation, Simulator Switcher, and Savings Calculator
   ========================================================================== */

document.addEventListener('DOMContentLoaded', () => {
  // --- 1. Mobile Menu Drawer Toggle ---
  const mobileMenuToggle = document.getElementById('mobileMenuToggle');
  const mobileDrawer = document.getElementById('mobileDrawer');
  
  if (mobileMenuToggle && mobileDrawer) {
    mobileMenuToggle.addEventListener('click', () => {
      mobileMenuToggle.classList.toggle('active');
      mobileDrawer.classList.toggle('open');
      
      // Prevent body scrolling when drawer is open
      if (mobileDrawer.classList.contains('open')) {
        document.body.style.overflow = 'hidden';
      } else {
        document.body.style.overflow = '';
      }
    });

    // Close drawer when clicking a link
    const drawerLinks = mobileDrawer.querySelectorAll('a');
    drawerLinks.forEach(link => {
      link.addEventListener('click', () => {
        mobileMenuToggle.classList.remove('active');
        mobileDrawer.classList.remove('open');
        document.body.style.overflow = '';
      });
    });
  }

  // --- 2. Interactive Mockup Switcher ---
  const switcherBtns = document.querySelectorAll('.switcher-btn');
  const demoViews = document.querySelectorAll('.demo-view');

  switcherBtns.forEach(btn => {
    btn.addEventListener('click', () => {
      // Deactivate all buttons
      switcherBtns.forEach(b => b.classList.remove('active'));
      // Activate clicked button
      btn.classList.add('active');

      // Get target view ID
      const targetId = btn.getAttribute('data-target');

      // Hide all views
      demoViews.forEach(view => {
        view.classList.remove('active');
      });

      // Show target view
      const targetView = document.getElementById(targetId);
      if (targetView) {
        targetView.classList.add('active');
      }
    });
  });

  // --- 3. Benefit Calculator Logic ---
  const rangeOmzet = document.getElementById('range-omzet');
  const rangeKasir = document.getElementById('range-kasir');
  const valOmzet = document.getElementById('val-omzet');
  const valKasir = document.getElementById('val-kasir');
  
  const resWaktu = document.getElementById('res-waktu');
  const resRugi = document.getElementById('res-rugi');

  function formatRupiah(value) {
    return new Intl.NumberFormat('id-ID', {
      style: 'currency',
      currency: 'IDR',
      minimumFractionDigits: 0,
      maximumFractionDigits: 0
    }).format(value);
  }

  function calculateSavings() {
    const omzetVal = parseInt(rangeOmzet.value, 10);
    const kasirVal = parseInt(rangeKasir.value, 10);

    // 1. Time Saved: Supposing a cashier takes 30 minutes (0.5 hour) daily for shift closing reconciliations
    // Saved per month = 30 days * count of cashiers * 0.5 hours
    const hoursSaved = Math.round(30 * kasirVal * 0.5);

    // 2. Revenue Leakage Prevented: Supposing manual cashiering has a 1% leakage rate (due to calculation errors, wrong change, etc.)
    // Saved per month = 30 days * daily revenue * 1%
    const leakageSaved = Math.round(30 * omzetVal * 0.01);

    // Update Text Values
    valOmzet.textContent = formatRupiah(omzetVal);
    valKasir.textContent = `${kasirVal} Orang`;
    
    // Update Results
    resWaktu.textContent = `${hoursSaved} Jam / Bulan`;
    resRugi.textContent = `${formatRupiah(leakageSaved)} / Bulan`;
  }

  if (rangeOmzet && rangeKasir) {
    rangeOmzet.addEventListener('input', calculateSavings);
    rangeKasir.addEventListener('input', calculateSavings);
    // Initial run
    calculateSavings();
  }

  // --- 4. Scroll Animations (Intersection Observer) ---
  const animateElements = document.querySelectorAll('.feature-card, .section-header, .pricing-card, .calculator-container, .hero-content, .hero-media');
  
  // Set up elements with animation class
  animateElements.forEach(el => {
    el.classList.add('animate-on-scroll');
  });

  if ('IntersectionObserver' in window) {
    const observerOptions = {
      root: null,
      rootMargin: '0px',
      threshold: 0.1
    };

    const observer = new IntersectionObserver((entries, observer) => {
      entries.forEach(entry => {
        if (entry.isIntersecting) {
          entry.target.classList.add('appear');
          observer.unobserve(entry.target); // Trigger once
        }
      });
    }, observerOptions);

    animateElements.forEach(el => {
      observer.observe(el);
    });
  } else {
    // Fallback: make them immediately visible
    animateElements.forEach(el => {
      el.classList.add('appear');
    });
  }
});
