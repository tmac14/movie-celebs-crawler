<?php

declare(strict_types = 1);

namespace App\Controller;

use Symfony\Component\DomCrawler\Crawler;
use Symfony\Component\HttpFoundation\JsonResponse;
use Symfony\Component\Panther\Client;
use Symfony\Component\Routing\Annotation\Route;

class IndexController
{
    private $client;

    /**
     * @Route("/", name="index")
     */
    public function __invoke(): JsonResponse
    {
        $mainUrl = 'https://www.sensacine.com/actores/todos/';
        $output = [];

        $client = Client::createChromeClient();
        $client->request('GET', $mainUrl);

        $crawlerAlphabetic = $client->waitFor('.filteralphazone');

        $charNodes = $crawlerAlphabetic->filter('.filteralphazone > a');
        
        for ($i=0; $i < $charNodes->count(); $i++) 
        {
            # save current firstname char URL
            $currentCharUrl = $charNodes->eq($i)->attr('href');
            
            # go to current firstname char URL to loop all names and save them into database
            $client->navigate()->to($currentCharUrl);

            # save all pages for current firstname char
            # first page is not a link
            $pages = $client->waitFor('.colgeneral');
            $pages = $pages->filter('.colgeneral .centeringtable .navcenterdata a');

            # get num of total pages
            $pagesLenght = (int) $pages->last()->text();
            
            # get page url format
            $pageFormat = $pages->eq(0)->attr('href'); 

            # save names from first page for the momment
            $names = $client->waitFor('.colgeneral');
            $names = $names
                ->filter('.colgeneral .datablock .titlebar a')
                ->each(function (Crawler $node) use (&$output) {
                    $output[] = [
                        'text' => strip_tags($node->html()),
                        'link' => $node->attr('href'),
                    ];
                });
        
            # loop rest of pages for this firstname char
            for ($x = 2; $x <= $pagesLenght; $x++) {
                $nextPage = preg_replace('/(\w+)=(\d+)/', '$1='.$x, $pageFormat);

                # navigate to next page
                $client->navigate()->to($nextPage); 
    
                # save names from current page
                $names = $client->waitFor('.colgeneral');
                $names = $names
                    ->filter('.colgeneral .datablock .titlebar a')
                    ->each(function (Crawler $node) use (&$output) {
                        $output[] = [
                            'text' => strip_tags($node->text()),
                            'link' => $node->attr('href'),
                        ];
                    });
            }

            if (1 === 1) break;
            
        }

        $client->quit();

        dump($output);

        return new JsonResponse($output);
    }
}
