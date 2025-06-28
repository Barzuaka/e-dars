// BEHAVIOUR FOR STICKY NAV AND ITS MENU ITEM HIGHLIGHTING
// /js/script.js - Robust Scrollspy Implementation using Intersection Observer

document.addEventListener('DOMContentLoaded', () => {
    const navLinks = document.querySelectorAll('.courses-filter-categories .category-link');
    const sections = document.querySelectorAll('.courses-by-category .category-group[id]');
    const stickyNav = document.querySelector('.courses-filter-categories');

    let stickyNavHeight = 0;
    if (stickyNav) {
        stickyNavHeight = stickyNav.offsetHeight;
    }

    // Function to set the active link
    const setActiveLink = (activeSectionId) => {
        // Remove 'active' from all links first
        navLinks.forEach(link => link.classList.remove('active'));

        // Add 'active' to the corresponding link
        if (activeSectionId) {
            const correspondingLink = document.querySelector(`.courses-filter-categories a[href="#${activeSectionId}"]`);
            if (correspondingLink) {
                correspondingLink.classList.add('active');
            }
        }
    };

    // Use Intersection Observer for more accurate section detection
    if ('IntersectionObserver' in window) {
        const observerOptions = {
            root: null, // Use viewport as root
            rootMargin: `-${stickyNavHeight + 30}px 0px -40% 0px`, // Balanced trigger point
            threshold: 0
        };

        const observer = new IntersectionObserver((entries) => {
            entries.forEach(entry => {
                if (entry.isIntersecting) {
                    setActiveLink(entry.target.id);
                }
            });
        }, observerOptions);

        // Observe all sections
        sections.forEach(section => {
            observer.observe(section);
        });
    } else {
        // Fallback for older browsers
        const setActiveLinkFallback = () => {
            const scrollY = window.scrollY;
            let currentSection = null;
            
            sections.forEach(section => {
                const sectionTop = section.offsetTop - stickyNavHeight - 50;
                const sectionBottom = sectionTop + section.offsetHeight;
                
                if (scrollY >= sectionTop && scrollY < sectionBottom) {
                    currentSection = section;
                }
            });
            
            if (sections.length > 0 && scrollY < sections[0].offsetTop - stickyNavHeight - 50) {
                currentSection = sections[0];
            }
            
            if (sections.length > 0 && scrollY >= sections[sections.length - 1].offsetTop - stickyNavHeight - 50) {
                currentSection = sections[sections.length - 1];
            }

            setActiveLink(currentSection ? currentSection.id : null);
        };

        let ticking = false;
        const handleScroll = () => {
            if (!ticking) {
                requestAnimationFrame(() => {
                    setActiveLinkFallback();
                    ticking = false;
                });
                ticking = true;
            }
        };

        window.addEventListener('scroll', handleScroll);
        setActiveLinkFallback();
    }
});