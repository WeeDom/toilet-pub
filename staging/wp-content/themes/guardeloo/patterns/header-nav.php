<?php
/**
 * Title: Header Navigation (Guard-e-Loo)
 * Slug: guardeloo/header-nav
 * Categories: header
 * Description: Warm autumnal header navigation featuring the Maggie image and color palette.
 */
?>

<!--
How it works (with flowcharts) GDPR / Privacy / CCTV explanation Incident workflow Council/pilot adoption info FAQs Contact
-->

<!-- wp:group {"align":"full","style":{"spacing":{"padding":{"top":"1rem","bottom":"1rem"}}},"backgroundColor":"gel-honey"} -->
<div class="wp-block-group alignfull has-gel-honey-background-color has-background" style="padding-top:1rem;padding-bottom:1rem">
  <!-- wp:columns {"align":"wide","verticalAlignment":"center","style":{"spacing":{"blockGap":"1rem"}}} -->
  <div class="wp-block-columns alignwide are-vertically-aligned-center">
    <!-- wp:column {"verticalAlignment":"center","width":"25%"} -->
    <div class="wp-block-column is-vertically-aligned-center" style="flex-basis:25%">
      <!-- wp:image {"sizeSlug":"full","linkDestination":"none"} -->
      <figure class="wp-block-image size-medium">
        <img src="<?php echo esc_url( get_stylesheet_directory_uri() . '/images/maggie.png' ); ?>" alt="Guard-e-Loo Logo" />
      </figure>
      <!-- /wp:image -->
    </div>
    <!-- /wp:column -->

    <!-- wp:column {"verticalAlignment":"center","width":"75%"} -->
    <div class="wp-block-column is-vertically-aligned-center" style="flex-basis:75%">
      <!-- wp:navigation {"overlayMenu":"never","layout":{"type":"flex","justifyContent":"right"},"textColor":"gel-brown","className":"site-nav"} -->
        <!-- wp:navigation-link {"label":"Home","url":"/"} /-->
        <!-- wp:navigation-link {"label":"How it works","url":"/how-it-works"} /-->
        <!-- wp:navigation-link {"label":"Privacy & GDPR","url":"/gdpr"} /-->
        <!-- wp:navigation-link {"label":"Contact","url":"/contact"} /-->
      <!-- /wp:navigation -->
    </div>
    <!-- /wp:column -->
  </div>
  <!-- /wp:columns -->
</div>
<!-- /wp:group -->
